# Автоматизация деплоя веб-приложения в Yandex Cloud через CI/CD

**ФИО:** Полтавский Марк Эдуардович
**Любимый вкус мороженого:** фисташка-шоколад

Состав репозитория:

- `terraform/` — инфраструктура (VPC, YCR, Managed Kubernetes, Managed PostgreSQL)
- `app/`, `Dockerfile` — простое веб-приложение (Flask), подключается к БД через `DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`
- `.github/workflows/deploy.yml` — CI/CD pipeline: build → push в YCR → обновление деплоймента в Kubernetes

## Шаг 1. Развёртывание инфраструктуры (Terraform)

```bash
cd terraform
terraform init
terraform apply \
  -var="cloud_id=<CLOUD_ID>" \
  -var="folder_id=<FOLDER_ID>" \
  -var="postgres_password=<ПАРОЛЬ_БД>" \
  -var="service_account_key_file=key.json"
```

После применения сохраните значения из `terraform output`:
`registry_id`, `k8s_cluster_name`, `postgres_fqdn`.

## Шаг 2. Контейнеризация

Приложение лежит в `app/`, читает переменные окружения `DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`.
Локальная проверка сборки:

```bash
docker build -t app:v1.0.0 .
```

## Шаг 3. Первичный запуск в Kubernetes (CLI)

```bash
yc managed-kubernetes cluster get-credentials <ИМЯ_КЛАСТЕРА> --external

kubectl create deployment web-app \
  --image=cr.yandex/<REGISTRY_ID>/app:v1.0.0 \
  --port=8080

kubectl set env deployment/web-app \
  DB_HOST=<FQDN_ХОСТА_POSTGRES> \
  DB_NAME=app_db \
  DB_USER=db_user \
  DB_PASSWORD=<ПАРОЛЬ_БД>

kubectl expose deployment web-app --type=LoadBalancer --port=80 --target-port=8080
```

## Шаг 4. Настройка CI/CD (GitHub Actions)

Workflow: `.github/workflows/deploy.yml`. При каждом push в `main`:
1. Авторизация в Yandex Cloud по ключу сервисного аккаунта.
2. `docker build` образа с тегом `${{ github.sha }}`.
3. `docker push` в Yandex Container Registry.
4. `kubectl set image deployment/web-app web-app=cr.yandex/<REGISTRY_ID>/app:${SHA}` (имя контейнера `web-app` — так его называет `kubectl create deployment` по умолчанию).

### Секреты, которые нужно добавить в GitHub (Settings → Secrets and variables → Actions)

| Секрет | Значение |
|---|---|
| `YC_SA_JSON_CREDENTIALS` | Содержимое JSON-ключа сервисного аккаунта (авторизованный ключ) |
| `YC_FOLDER_ID` | ID каталога в Yandex Cloud |
| `YC_REGISTRY_ID` | ID реестра (`terraform output registry_id`) |
| `YC_CLUSTER_NAME` | Имя кластера Kubernetes |

Создание ключа сервисного аккаунта:

```bash
yc iam key create \
  --service-account-name <ИМЯ_SA> \
  --output key.json
```

## Скриншот работающего приложения

Внешний IP сервиса берётся из:

```bash
kubectl get service web-app
```

Приложение доступно по `http://<EXTERNAL-IP>/` и `http://<EXTERNAL-IP>/health` (проверка подключения к БД).

Скриншот работающего приложения по внешнему IP приложен отдельно к сдаче задания.

## Важные нюансы security group (Managed Kubernetes в Yandex Cloud)

Без явных правил в security group следующее не будет работать:

- **Доступ к API кластера снаружи** — нужно разрешить входящий TCP 443/6443 от `0.0.0.0/0` (см. `terraform/kubernetes.tf`).
- **Сервисы типа `LoadBalancer`** — Network Load Balancer не пройдёт health-check нод и не будет пропускать трафик, если не разрешить входящий трафик от служебных диапазонов `198.18.235.0/24` и `198.18.248.0/24`.
- **Подключение подов к Managed PostgreSQL** — нужно разрешить вход на порт 5432/6432 не только из подсети ноды, но и из CIDR подов кластера (`cluster_ipv4_cidr_block`, по умолчанию `10.112.0.0/16`), так как Yandex Managed Kubernetes маршрутизирует трафик от подов напрямую (без SNAT на IP ноды).

Также на некоторых аккаунтах (например, грантовых/учебных) применение изменений security group к уже созданным managed-ресурсам может не подхватываться сетью движком — в этом случае помогает пересоздание ресурса (`terraform apply -replace=<resource>`).

# Автоматизация деплоя веб-приложения в Yandex Cloud через CI/CD

**ФИО:** _<укажите ФИО>_
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

# Переименовать контейнер в app-container, чтобы имя совпадало
# с тем, что использует CI/CD pipeline (kubectl set image ... app-container=...)
kubectl patch deployment web-app --type=json -p \
  '[{"op":"replace","path":"/spec/template/spec/containers/0/name","value":"app-container"}]'

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
4. `kubectl set image deployment/web-app app-container=cr.yandex/<REGISTRY_ID>/app:${SHA}`.

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

_<здесь будет скриншот браузера с открытым внешним IP>_

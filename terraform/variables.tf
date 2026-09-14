variable "service_account_key_file" {
  description = "Путь к JSON-ключу сервисного аккаунта Yandex Cloud"
  type        = string
  default     = "key.json"
}

variable "cloud_id" {
  description = "ID облака в Yandex Cloud"
  type        = string
}

variable "folder_id" {
  description = "ID каталога (folder) в Yandex Cloud"
  type        = string
}

variable "zone" {
  description = "Зона доступности"
  type        = string
  default     = "ru-central1-a"
}

variable "network_name" {
  description = "Имя VPC-сети"
  type        = string
  default     = "web-app-network"
}

variable "subnet_cidr" {
  description = "CIDR публичной подсети"
  type        = string
  default     = "10.10.0.0/24"
}

variable "registry_name" {
  description = "Имя реестра Yandex Container Registry"
  type        = string
  default     = "web-app-registry"
}

variable "k8s_cluster_name" {
  description = "Имя кластера Managed Service for Kubernetes"
  type        = string
  default     = "web-app-cluster"
}

variable "k8s_node_count" {
  description = "Количество узлов в node group кластера K8s"
  type        = number
  default     = 2
}

variable "k8s_node_resources" {
  description = "Ресурсы одного узла K8s (cores/memory в GB)"
  type = object({
    cores  = number
    memory = number
  })
  default = {
    cores  = 2
    memory = 4
  }
}

variable "postgres_cluster_name" {
  description = "Имя кластера Managed Service for PostgreSQL"
  type        = string
  default     = "web-app-postgres"
}

variable "postgres_db_name" {
  description = "Имя базы данных приложения"
  type        = string
  default     = "app_db"
}

variable "postgres_user" {
  description = "Имя пользователя БД приложения"
  type        = string
  default     = "db_user"
}

variable "postgres_password" {
  description = "Пароль пользователя БД приложения"
  type        = string
  sensitive   = true
}

variable "postgres_resources" {
  description = "Ресурсы хоста PostgreSQL"
  type = object({
    resource_preset_id = string
    disk_size          = number
    disk_type_id       = string
  })
  default = {
    resource_preset_id = "s2.micro"
    disk_size          = 20
    disk_type_id       = "network-ssd"
  }
}

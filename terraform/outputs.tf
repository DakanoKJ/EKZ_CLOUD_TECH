output "registry_id" {
  description = "ID реестра Yandex Container Registry (используется в тегах образов cr.yandex/<REGISTRY_ID>/...)"
  value       = yandex_container_registry.app_registry.id
}

output "k8s_cluster_id" {
  description = "ID кластера Kubernetes"
  value       = yandex_kubernetes_cluster.app_cluster.id
}

output "k8s_cluster_name" {
  description = "Имя кластера Kubernetes (для yc managed-kubernetes cluster get-credentials)"
  value       = yandex_kubernetes_cluster.app_cluster.name
}

output "postgres_fqdn" {
  description = "FQDN хоста PostgreSQL (для DB_HOST)"
  value       = yandex_mdb_postgresql_cluster.app_postgres.host[0].fqdn
}

output "postgres_db_name" {
  value = var.postgres_db_name
}

output "postgres_user" {
  value = var.postgres_user
}

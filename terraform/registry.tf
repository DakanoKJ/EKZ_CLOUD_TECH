resource "yandex_container_registry" "app_registry" {
  name      = var.registry_name
  folder_id = var.folder_id
}

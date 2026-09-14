resource "yandex_mdb_postgresql_cluster" "app_postgres" {
  name        = var.postgres_cluster_name
  environment = "PRESTABLE"
  network_id  = yandex_vpc_network.app_network.id

  config {
    version = "15"
    resources {
      resource_preset_id = var.postgres_resources.resource_preset_id
      disk_size          = var.postgres_resources.disk_size
      disk_type_id       = var.postgres_resources.disk_type_id
    }
  }

  host {
    zone      = var.zone
    subnet_id = yandex_vpc_subnet.app_subnet.id
  }

  database {
    name  = var.postgres_db_name
    owner = var.postgres_user
  }

  user {
    name     = var.postgres_user
    password = var.postgres_password
    permission {
      database_name = var.postgres_db_name
    }
  }
}

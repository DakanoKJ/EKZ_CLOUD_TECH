# Сервисный аккаунт для управления кластером и доступа к реестру
resource "yandex_iam_service_account" "k8s_sa" {
  name = "${var.k8s_cluster_name}-sa"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_sa_editor" {
  folder_id = var.folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_sa_registry_puller" {
  folder_id = var.folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_sa.id}"
}

resource "yandex_kubernetes_cluster" "app_cluster" {
  name       = var.k8s_cluster_name
  network_id = yandex_vpc_network.app_network.id

  master {
    version = "1.28"
    zonal {
      zone      = var.zone
      subnet_id = yandex_vpc_subnet.app_subnet.id
    }
    public_ip = true
  }

  service_account_id      = yandex_iam_service_account.k8s_sa.id
  node_service_account_id = yandex_iam_service_account.k8s_sa.id

  depends_on = [
    yandex_resourcemanager_folder_iam_member.k8s_sa_editor,
  ]
}

resource "yandex_kubernetes_node_group" "app_node_group" {
  cluster_id = yandex_kubernetes_cluster.app_cluster.id
  name       = "${var.k8s_cluster_name}-nodes"
  version    = "1.28"

  instance_template {
    platform_id = "standard-v3"

    network_interface {
      nat        = true
      subnet_ids = [yandex_vpc_subnet.app_subnet.id]
    }

    resources {
      cores  = var.k8s_node_resources.cores
      memory = var.k8s_node_resources.memory
    }

    boot_disk {
      type = "network-hdd"
      size = 64
    }
  }

  scale_policy {
    fixed_scale {
      size = var.k8s_node_count
    }
  }

  allocation_policy {
    location {
      zone = var.zone
    }
  }
}

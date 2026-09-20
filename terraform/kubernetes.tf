# Группа безопасности: без явных правил Yandex Cloud блокирует внешний
# доступ к API мастера и к сервисам типа LoadBalancer на нодах.
resource "yandex_vpc_security_group" "k8s_sg" {
  name       = "${var.k8s_cluster_name}-sg"
  network_id = yandex_vpc_network.app_network.id

  ingress {
    protocol       = "TCP"
    description    = "Доступ к Kubernetes API"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 443
  }

  ingress {
    protocol       = "TCP"
    description    = "Доступ к Kubernetes API (альтернативный порт)"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 6443
  }

  ingress {
    protocol       = "TCP"
    description    = "NodePort / LoadBalancer сервисы"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 30000
    to_port        = 32767
  }

  # Без этого правила Network Load Balancer не может пройти health-check
  # нод и не пропускает трафик наружу (сервис типа LoadBalancer не работает).
  ingress {
    protocol    = "ANY"
    description = "Health-check от Yandex Network Load Balancer"
    v4_cidr_blocks = [
      "198.18.235.0/24",
      "198.18.248.0/24",
    ]
    from_port = 0
    to_port   = 65535
  }

  ingress {
    protocol       = "TCP"
    description    = "HTTP к приложению"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol       = "TCP"
    description    = "PostgreSQL из подсети и от подов кластера"
    v4_cidr_blocks = [var.subnet_cidr, "10.112.0.0/16"]
    port           = 6432
  }

  ingress {
    protocol       = "TCP"
    description    = "PostgreSQL из подсети и от подов кластера (прямой порт)"
    v4_cidr_blocks = [var.subnet_cidr, "10.112.0.0/16"]
    port           = 5432
  }

  ingress {
    protocol          = "ANY"
    description       = "Внутрикластерный трафик"
    predefined_target = "self_security_group"
    from_port         = 0
    to_port           = 65535
  }

  egress {
    protocol       = "ANY"
    description    = "Весь исходящий трафик"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

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
    version = "1.32"
    zonal {
      zone      = var.zone
      subnet_id = yandex_vpc_subnet.app_subnet.id
    }
    public_ip          = true
    security_group_ids = [yandex_vpc_security_group.k8s_sg.id]
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
  version    = "1.32"

  instance_template {
    platform_id = "standard-v3"

    network_interface {
      nat                = true
      subnet_ids         = [yandex_vpc_subnet.app_subnet.id]
      security_group_ids = [yandex_vpc_security_group.k8s_sg.id]
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

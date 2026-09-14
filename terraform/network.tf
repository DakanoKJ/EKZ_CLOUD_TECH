resource "yandex_vpc_network" "app_network" {
  name = var.network_name
}

resource "yandex_vpc_subnet" "app_subnet" {
  name           = "${var.network_name}-subnet"
  zone           = var.zone
  network_id     = yandex_vpc_network.app_network.id
  v4_cidr_blocks = [var.subnet_cidr]
}

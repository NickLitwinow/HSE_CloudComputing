resource "yandex_vpc_network" "net" {
  name = "hw2-network"
}

resource "yandex_vpc_subnet" "public" {
  name = "hw2-public-subnet"
  zone = var.zone
  network_id = yandex_vpc_network.net.id
  v4_cidr_blocks = ["10.10.1.0/24"]
}

resource "yandex_vpc_subnet" "private" {
  name = "hw2-private-subnet"
  zone = var.zone
  network_id = yandex_vpc_network.net.id
  v4_cidr_blocks = ["10.10.2.0/24"]
  route_table_id = yandex_vpc_route_table.nat_route.id
}

resource "yandex_vpc_route_table" "nat_route" {
  name = "hw2-nat-route-table"
  network_id = yandex_vpc_network.net.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address = "10.10.1.254"
  }
}

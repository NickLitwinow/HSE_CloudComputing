resource "yandex_vpc_security_group" "nat_sg" {
  name = "hw2-nat-sg"
  network_id = yandex_vpc_network.net.id

  ingress {
    protocol = "TCP"
    description = "SSH from My IP"
    port = 22
    v4_cidr_blocks = [var.my_ip_cidr]
  }

  ingress {
    protocol = "ANY"
    description = "Allow local subnet traffic"
    v4_cidr_blocks = ["10.10.0.0/16"]
  }

  egress {
    protocol = "ANY"
    description = "Allow all egress"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "lb_sg" {
  name = "hw2-lb-sg"
  network_id = yandex_vpc_network.net.id

  ingress {
    protocol = "TCP"
    description = "HTTP from Internet"
    port = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    protocol = "TCP"
    description = "SSH from My IP"
    port = 22
    v4_cidr_blocks = [var.my_ip_cidr]
  }

  egress {
    protocol = "ANY"
    description = "Allow all egress"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "internal_sg" {
  name = "hw2-internal-sg"
  network_id = yandex_vpc_network.net.id

  # Allow SSH from public subnet (NAT/Jump host)
  ingress {
    protocol = "TCP"
    description    = "SSH from Public Subnet"
    port           = 22
    v4_cidr_blocks = ["10.10.1.0/24"]
  }

  # Allow HTTP from Public Subnet (Nginx to Logbrokers)
  ingress {
    protocol = "TCP"
    description = "HTTP from Nginx"
    port = 80
    v4_cidr_blocks = ["10.10.1.0/24"]
  }

  # Allow ClickHouse traffic (8123 http, 9000 tcp) from Private Subnet (Logbrokers)
  ingress {
    protocol = "TCP"
    description = "ClickHouse from Private Subnet"
    from_port = 8123
    to_port = 9000
    v4_cidr_blocks = ["10.10.2.0/24"]
  }

  egress {
    protocol = "ANY"
    description = "Allow all egress"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

terraform {
  required_version = ">= 1.3"

  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
      version = ">= 0.88.0"
    }
  }
}

provider "yandex" {
  service_account_key_file = var.sa_key_file
  cloud_id = var.cloud_id
  folder_id = var.folder_id
  zone = var.zone
}

data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
}

resource "yandex_vpc_network" "net" {
  name = "hw-net"
}

resource "yandex_vpc_subnet" "subnet" {
  name = "hw-subnet"
  zone = var.zone
  network_id = yandex_vpc_network.net.id
  v4_cidr_blocks = ["10.10.0.0/24"]
}

resource "yandex_vpc_security_group" "sg" {
  name = "hw-sg"
  network_id = yandex_vpc_network.net.id

  ingress {
    protocol = "TCP"
    description = "SSH"
    port = 22
    v4_cidr_blocks = [var.my_ip_cidr]
  }

  ingress {
    protocol = "TCP"
    description = "code-server"
    port = 8080
    v4_cidr_blocks = [var.my_ip_cidr]
  }

  egress {
    protocol = "ANY"
    description = "Allow all egress"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_compute_instance" "vm" {
  name = "hw-vm"
  platform_id = "standard-v3"
  zone = var.zone

  resources {
    cores = 2
    memory = 1
    core_fraction = 20
  }

  scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size = 13
      type = "network-hdd"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet.id
    nat = true
    security_group_ids = [yandex_vpc_security_group.sg.id]
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
    user-data = file("${path.module}/cloud-init.yaml")
  }
}

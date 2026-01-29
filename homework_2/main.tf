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
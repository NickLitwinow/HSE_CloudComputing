variable "sa_key_file" {
  type = string
  description = "Path to service account key.json"
}

variable "cloud_id" {
  type = string
  description = "Yandex Cloud cloud_id"
}

variable "folder_id" {
  type = string
  description = "Yandex Cloud folder_id"
}

variable "zone" {
  type = string
  description = "Availability zone, e.g. ru-central1-a"
  default = "ru-central1-a"
}

variable "ssh_user" {
  type = string
  description = "SSH username"
  default = "ubuntu"
}

variable "ssh_public_key_path" {
  type = string
  description = "Path to your public SSH key"
}

variable "my_ip_cidr" {
  type = string
  description = "Your external IP in CIDR (/32), e.g. 1.2.3.4/32"
}

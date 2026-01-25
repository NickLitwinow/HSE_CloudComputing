output "external_ip" {
  value = yandex_compute_instance.vm.network_interface[0].nat_ip_address
}

output "ssh_command" {
  value = "ssh -i ${var.ssh_public_key_path} ${var.ssh_user}@${yandex_compute_instance.vm.network_interface[0].nat_ip_address}"
}

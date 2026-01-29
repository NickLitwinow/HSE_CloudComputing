output "nginx_public_ip" {
  value = yandex_compute_instance.nginx.network_interface.0.nat_ip_address
}

output "nat_public_ip" {
  value = yandex_compute_instance.nat.network_interface.0.nat_ip_address
}

output "clickhouse_ip" {
  value = yandex_compute_instance.clickhouse.network_interface.0.ip_address
}

output "app_ips" {
  value = yandex_compute_instance.app.*.network_interface.0.ip_address
}

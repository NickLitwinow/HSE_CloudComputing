resource "yandex_compute_instance" "clickhouse" {
  name = "hw2-clickhouse"
  platform_id = "standard-v3"
  zone = var.zone
  hostname = "clickhouse"

  resources {
    cores = 2
    memory = 4
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size = 20
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.private.id
    security_group_ids = [yandex_vpc_security_group.internal_sg.id]
    ip_address = "10.10.2.10"
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
    user-data = <<-EOF
      #cloud-config
      users:
        - name: litwein
          groups: sudo
          shell: /bin/bash
          sudo: ['ALL=(ALL) NOPASSWD:ALL']
          ssh_authorized_keys:
            - ${file(var.ssh_public_key_path)}
      package_update: true
      packages:
        - docker.io
      runcmd:
        - mkdir -p /home/ubuntu/logbroker_clickhouse_database
        - docker run -d --name clickhouse-server --ulimit nofile=262144:262144 -p 8123:8123 -p 9000:9000 --volume=/home/ubuntu/logbroker_clickhouse_database:/var/lib/clickhouse yandex/clickhouse-server
        - sleep 30
        - docker run --rm --link clickhouse-server:clickhouse-server yandex/clickhouse-client --host clickhouse-server --query "CREATE TABLE IF NOT EXISTS default.logs (a Int32, b String) ENGINE = MergeTree() PRIMARY KEY a ORDER BY a;"
    EOF
  }

  scheduling_policy {
    preemptible = true
  }
}

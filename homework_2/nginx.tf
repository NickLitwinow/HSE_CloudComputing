resource "yandex_compute_instance" "nginx" {
  name = "hw2-nginx"
  platform_id = "standard-v3"
  zone = var.zone

  resources {
    cores = 2
    memory = 1
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size = 10
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.public.id
    nat = true
    security_group_ids = [yandex_vpc_security_group.lb_sg.id]
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
        - nginx
      write_files:
        - content: |
            upstream logbroker {
                server 10.10.2.20:80;
                server 10.10.2.21:80;
            }
            server {
                listen 80;
                location / {
                    proxy_pass http://logbroker;
                    proxy_set_header Host \$host;
                    proxy_set_header X-Real-IP \$remote_addr;
                }
            }
          path: /etc/nginx/sites-available/logbroker
      runcmd:
        - rm /etc/nginx/sites-enabled/default
        - ln -s /etc/nginx/sites-available/logbroker /etc/nginx/sites-enabled/
        - systemctl restart nginx
    EOF
  }

  scheduling_policy {
    preemptible = true
  }
}

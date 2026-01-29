resource "yandex_compute_instance" "nat" {
  name = "hw2-nat"
  platform_id = "standard-v3"
  zone = var.zone

  resources {
    cores  = 2
    memory = 2
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
    ip_address = "10.10.1.254"
    security_group_ids = [yandex_vpc_security_group.nat_sg.id]
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
    # Enable IP forwarding for NAT
    user-data = <<-EOF
      #cloud-config
      users:
        - name: litwein
          groups: sudo
          shell: /bin/bash
          sudo: ['ALL=(ALL) NOPASSWD:ALL']
          ssh_authorized_keys:
            - ${file(var.ssh_public_key_path)}
      runcmd:
        - echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
        - sysctl -p
        - iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
        - iptables-save > /etc/iptables/rules.v4
        # install iptables-persistent to save rules (if interactive is avoided) or just use rc.local
        # simpler approach for homework: allow it in rc.local or systemd service
        - echo "iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE" >> /etc/rc.local
        - chmod +x /etc/rc.local
    EOF
  }

  scheduling_policy {
    preemptible = true
  }
}

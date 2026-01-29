resource "yandex_compute_instance" "app" {
  count = 2
  name = "hw2-app-${count.index + 1}"
  platform_id = "standard-v3"
  zone = var.zone
  hostname = "app-${count.index + 1}"

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
    subnet_id = yandex_vpc_subnet.private.id
    security_group_ids = [yandex_vpc_security_group.internal_sg.id]
    ip_address = "10.10.2.2${count.index}"
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
    
    # Python App & Sender implementation embedded
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
        - python3-pip
        - python3-venv
      write_files:
        - content: |
            from fastapi import FastAPI, Request
            import uvicorn
            import json
            import os

            app = FastAPI()
            BUFFER_FILE = "/var/log/logbroker.wal"

            @app.post("/")
            async def write_log(request: Request):
                data = await request.json()
                # Simple WAL append
                with open(BUFFER_FILE, "a") as f:
                    f.write(json.dumps(data) + "\n")
                return {"status": "ok"}

            if __name__ == "__main__":
                uvicorn.run(app, host="0.0.0.0", port=80)
          path: /home/litwein/app.py
        
        - content: |
            import time
            import os
            import requests
            import shutil

            BUFFER_FILE = "/var/log/logbroker.wal"
            PROCESSING_FILE = "/var/log/logbroker.processing"
            CLICKHOUSE_URL = "http://10.10.2.10:8123/"
            TABLE = "default.logs"

            def send_to_clickhouse(data):
                query = f"INSERT INTO {TABLE} FORMAT JSONEachRow"
                try:
                    response = requests.post(CLICKHOUSE_URL, params={"query": query}, data=data)
                    if response.status_code != 200:
                        print(f"Error sending to CH: {response.text}")
                        return False
                    return True
                except Exception as e:
                    print(f"Exception sending to CH: {e}")
                    return False

            def main():
                while True:
                    if os.path.exists(BUFFER_FILE) and os.path.getsize(BUFFER_FILE) > 0:
                        try:
                            shutil.move(BUFFER_FILE, PROCESSING_FILE)
                        except Exception as e:
                            print(f"Error moving file: {e}")
                            time.sleep(1)
                            continue

                        try:
                            with open(PROCESSING_FILE, "r") as f:
                                data = f.read()
                            
                            if send_to_clickhouse(data):
                                os.remove(PROCESSING_FILE)
                            else:
                                with open(BUFFER_FILE, "a") as f:
                                    f.write(data)
                                os.remove(PROCESSING_FILE)
                                
                        except Exception as e:
                           print(f"Processing error: {e}")
                    
                    time.sleep(1)

            if __name__ == "__main__":
                main()
          path: /home/litwein/sender.py

        - content: |
            [Unit]
            Description=Logbroker App
            After=network.target

            [Service]
            User=root
            WorkingDirectory=/home/litwein
            ExecStart=/usr/bin/python3 /home/litwein/app.py
            Restart=always

            [Install]
            WantedBy=multi-user.target
          path: /etc/systemd/system/logbroker-app.service

        - content: |
            [Unit]
            Description=Logbroker Sender
            After=network.target

            [Service]
            User=root
            WorkingDirectory=/home/litwein
            ExecStart=/usr/bin/python3 /home/litwein/sender.py
            Restart=always

            [Install]
            WantedBy=multi-user.target
          path: /etc/systemd/system/logbroker-sender.service

      runcmd:
        - pip3 install fastapi uvicorn requests
        - touch /var/log/logbroker.wal
        - chmod 666 /var/log/logbroker.wal
        - systemctl daemon-reload
        - systemctl enable --now logbroker-app
        - systemctl enable --now logbroker-sender
    EOF
  }

  scheduling_policy {
    preemptible = true
  }
}

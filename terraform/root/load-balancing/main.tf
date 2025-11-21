resource "incus_project" "project" {
  name        = var.project_name
  description = "Load balancing project with 3 instances and a load balancer"
  remote      = "incus-server-root"
}

resource "incus_network" "ovn" {
  name    = "ovn"
  type    = "ovn"
  project = incus_project.project.name
  remote  = "incus-server-root"

  config = {
    "ipv4.nat" = "true"
  }

  depends_on = [incus_project.project]
}

resource "incus_profile" "profile" {
  name    = "load-balancing-profile"
  project = incus_project.project.name
  remote  = "incus-server-root"

  device {
    name = "root"
    type = "disk"
    properties = {
      path = "/"
      pool = var.storage_pool
    }
  }

  depends_on = [incus_project.project]
}

locals {
  instance_names = ["instance-1", "instance-2", "instance-3"]
}

resource "incus_instance" "web_instances" {
  count    = length(local.instance_names)
  name     = local.instance_names[count.index]
  image    = var.instance_image
  type     = var.instance_type
  project  = incus_project.project.name
  remote   = "incus-server-root"
  profiles = [incus_profile.profile.name]

  config = {
    "limits.cpu"    = "1"
    "limits.memory" = "512MB"
  }

  device {
    name = "eth0"
    type = "nic"
    properties = {
      network = incus_network.ovn.name
    }
  }

  depends_on = [incus_project.project, incus_profile.profile, incus_network.ovn]
}

locals {
  web_server_script = <<-EOF
#!/usr/bin/env python3
import http.server
import socketserver
from http.server import BaseHTTPRequestHandler
import socket

class MyHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        hostname = socket.gethostname()
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        message = f"<html><body><h1>you are connected to {hostname}</h1></body></html>"
        self.wfile.write(bytes(message, "utf8"))
        return

PORT = 8080

with socketserver.TCPServer(("", PORT), MyHandler) as httpd:
    print(f"Server running on port {PORT}")
    httpd.serve_forever()
EOF
}

resource "null_resource" "setup_web_servers" {
  count = length(incus_instance.web_instances)

  triggers = {
    instance_name = incus_instance.web_instances[count.index].name
    instance_ip   = incus_instance.web_instances[count.index].ipv4_address
  }

  provisioner "local-exec" {
    command = <<-EOT
      export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"
      INCUS_CMD=$(command -v incus || which incus || echo "incus")
      cat > /tmp/web_server_${count.index}.py <<'PYTHON_SCRIPT'
${local.web_server_script}
PYTHON_SCRIPT
      $INCUS_CMD file push /tmp/web_server_${count.index}.py --project ${incus_project.project.name} --remote incus-server-root ${incus_instance.web_instances[count.index].name}/opt/web_server.py
      rm -f /tmp/web_server_${count.index}.py
      $INCUS_CMD exec ${incus_instance.web_instances[count.index].name} --project ${incus_project.project.name} --remote incus-server-root -- bash -c "
        chmod +x /opt/web_server.py &&
        apt-get update -qq &&
        apt-get install -y -qq python3 > /dev/null 2>&1 &&
        nohup python3 /opt/web_server.py > /var/log/web_server.log 2>&1 &
      "
    EOT
  }

  depends_on = [incus_instance.web_instances]
}

resource "incus_network_lb" "load_balancer" {
  network        = incus_network.ovn.name
  project        = incus_project.project.name
  remote         = "incus-server-root"
  description    = "Load balancer for web instances"
  listen_address = var.listen_address

  backend {
    name           = "instance-1"
    description    = "Load Balancer Backend - instance-1"
    target_address = incus_instance.web_instances[0].ipv4_address
    target_port    = "8080"
  }

  backend {
    name           = "instance-2"
    description    = "Load Balancer Backend - instance-2"
    target_address = incus_instance.web_instances[1].ipv4_address
    target_port    = "8080"
  }

  backend {
    name           = "instance-3"
    description    = "Load Balancer Backend - instance-3"
    target_address = incus_instance.web_instances[2].ipv4_address
    target_port    = "8080"
  }

  port {
    description    = "Port ${var.http_port}/tcp"
    protocol       = "tcp"
    listen_port    = tostring(var.http_port)
    target_backend = ["instance-1", "instance-2", "instance-3"]
  }

  depends_on = [incus_network.ovn, incus_instance.web_instances, null_resource.setup_web_servers]
}

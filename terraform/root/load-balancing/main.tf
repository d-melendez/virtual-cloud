resource "incus_project" "project" {
  name        = var.project_name
  description = "Load balancing project with 3 instances and a load balancer"
  remote      = local.remote_name
}

resource "random_string" "net_suffix" {
  length  = 4
  special = false
  upper   = false

  keepers = {
    project = var.project_name
  }
}

resource "random_integer" "net_octet" {
  min = 20
  max = 250

  keepers = {
    project = var.project_name
  }
}

resource "incus_network" "ovn" {
  name    = "lb-${substr(var.project_name, 0, 7)}-${random_string.net_suffix.result}"
  type    = "bridge"
  project = incus_project.project.name
  remote  = local.remote_name

  config = {
    "ipv4.address" = coalesce(var.bridge_ipv4_cidr, format("10.%d.0.1/24", random_integer.net_octet.result))
    "ipv4.dhcp"    = "true"
    "ipv6.address" = "none"
    "ipv4.nat"     = "true"
  }

  depends_on = [incus_project.project]
}

resource "incus_profile" "profile" {
  name    = "load-balancing-profile-${var.project_name}"
  project = incus_project.project.name
  remote  = local.remote_name

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
  remote   = local.remote_name
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
      if ! command -v incus >/dev/null 2>&1 && command -v brew >/dev/null 2>&1; then
        brew install incus
      fi
      $INCUS_CMD remote list | awk '{print $1}' | grep -qx ${local.remote_name} || $INCUS_CMD remote add ${local.remote_name} ${var.incus_endpoint} --accept-certificate --auth-type tls --token ${var.incus_token}
      cat > /tmp/web_server_${count.index}.py <<'PYTHON_SCRIPT'
${local.web_server_script}
PYTHON_SCRIPT
      $INCUS_CMD --project ${incus_project.project.name} file push /tmp/web_server_${count.index}.py ${local.remote_name}:${incus_instance.web_instances[count.index].name}/opt/web_server.py
      rm -f /tmp/web_server_${count.index}.py
      $INCUS_CMD --project ${incus_project.project.name} exec ${local.remote_name}:${incus_instance.web_instances[count.index].name} -- bash -c "
        chmod +x /opt/web_server.py &&
        apt-get update -qq &&
        apt-get install -y -qq python3 > /dev/null 2>&1 &&
        nohup python3 /opt/web_server.py > /var/log/web_server.log 2>&1 &
      "
    EOT
  }

  depends_on = [incus_instance.web_instances]
}

resource "incus_instance" "lb" {
  name     = "load-balancer"
  image    = var.instance_image
  type     = var.instance_type
  project  = incus_project.project.name
  remote   = local.remote_name
  profiles = [incus_profile.profile.name]

  device {
    name = "eth0"
    type = "nic"
    properties = {
      network = incus_network.ovn.name
    }
  }

  device {
    name = "http"
    type = "proxy"
    properties = {
      listen  = "tcp:0.0.0.0:${var.http_port}"
      connect = "tcp:127.0.0.1:8080"
      bind    = "host"
    }
  }

  depends_on = [incus_profile.profile, incus_network.ovn]
}

resource "null_resource" "setup_lb" {
  triggers = {
    instance_1_ip = incus_instance.web_instances[0].ipv4_address
    instance_2_ip = incus_instance.web_instances[1].ipv4_address
    instance_3_ip = incus_instance.web_instances[2].ipv4_address
  }

  provisioner "local-exec" {
    command = <<-EOT
      export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"
      INCUS_CMD=$(command -v incus || which incus || echo "incus")
      if ! command -v incus >/dev/null 2>&1 && command -v brew >/dev/null 2>&1; then
        brew install incus
      fi
      $INCUS_CMD remote list | awk '{print $1}' | grep -qx ${local.remote_name} || $INCUS_CMD remote add ${local.remote_name} ${var.incus_endpoint} --accept-certificate --auth-type tls --token ${var.incus_token}
      $INCUS_CMD --project ${incus_project.project.name} exec ${local.remote_name}:${incus_instance.lb.name} -- bash -c "
        apt-get update -qq &&
        apt-get install -y -qq haproxy > /dev/null 2>&1
      "
      cat > /tmp/haproxy.cfg <<'HAPROXY_CFG'
global
    daemon
    maxconn 256

defaults
    mode http
    timeout connect 5s
    timeout client  50s
    timeout server  50s

frontend http-in
    bind *:8080
    default_backend servers

backend servers
    balance roundrobin
    server s1 ${incus_instance.web_instances[0].ipv4_address}:8080 check
    server s2 ${incus_instance.web_instances[1].ipv4_address}:8080 check
    server s3 ${incus_instance.web_instances[2].ipv4_address}:8080 check
HAPROXY_CFG
      $INCUS_CMD --project ${incus_project.project.name} file push /tmp/haproxy.cfg ${local.remote_name}:${incus_instance.lb.name}/etc/haproxy/haproxy.cfg
      rm -f /tmp/haproxy.cfg
      $INCUS_CMD --project ${incus_project.project.name} exec ${local.remote_name}:${incus_instance.lb.name} -- bash -c "
        nohup haproxy -f /etc/haproxy/haproxy.cfg -db > /var/log/haproxy.log 2>&1 &
      "
    EOT
  }

  depends_on = [incus_instance.lb, incus_instance.web_instances, null_resource.setup_web_servers]
}

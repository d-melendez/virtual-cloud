resource "incus_project" "project" {
  name        = var.project_name
  description = "MinIO S3-compatible storage project"
  remote      = local.remote_name
}

locals {
  host_from_endpoint = split(":", replace(replace(var.incus_endpoint, "https://", ""), "http://", ""))[0]
  host_ssh_address   = coalesce(var.host_ssh_address, local.host_from_endpoint)
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

resource "incus_network" "net" {
  name    = "mn-${substr(var.project_name, 0, 7)}-${random_string.net_suffix.result}"
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
  name    = "minio-profile-${var.project_name}"
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

resource "incus_instance" "minio" {
  name     = "minio"
  image    = var.instance_image
  type     = var.instance_type
  project  = incus_project.project.name
  remote   = local.remote_name
  profiles = [incus_profile.profile.name]

  config = {
    "limits.cpu"    = "1"
    "limits.memory" = "1GB"
  }

  device {
    name = "eth0"
    type = "nic"
    properties = {
      network = incus_network.net.name
    }
  }

  device {
    name = "s3"
    type = "proxy"
    properties = {
      listen  = "tcp:0.0.0.0:${var.s3_port}"
      connect = "tcp:127.0.0.1:${var.minio_internal_s3_port}"
      bind    = "host"
    }
  }

  device {
    name = "console"
    type = "proxy"
    properties = {
      listen  = "tcp:0.0.0.0:${var.console_port}"
      connect = "tcp:127.0.0.1:${var.minio_internal_console_port}"
      bind    = "host"
    }
  }

  depends_on = [incus_profile.profile, incus_network.net]
}

resource "null_resource" "setup_minio" {
  triggers = {
    instance_name = incus_instance.minio.name
    instance_ip   = incus_instance.minio.ipv4_address
  }

  provisioner "local-exec" {
    command = <<-EOT
      export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"
      INCUS_CMD=$(command -v incus || which incus || echo "incus")
      if ! command -v incus >/dev/null 2>&1 && command -v brew >/dev/null 2>&1; then
        brew install incus
      fi
      $INCUS_CMD remote get-url ${local.remote_name} >/dev/null 2>&1 || $INCUS_CMD remote add ${local.remote_name} ${var.incus_endpoint} --accept-certificate --auth-type tls --token ${var.incus_token} || true
      $INCUS_CMD --project ${incus_project.project.name} exec ${local.remote_name}:${incus_instance.minio.name} -- bash -c "
        set -eu
        apt-get update -qq &&
        apt-get install -y -qq curl ca-certificates > /dev/null 2>&1 &&
        mkdir -p /usr/local/bin &&
        curl -fsSL -o /tmp/minio https://dl.min.io/server/minio/release/linux-amd64/minio &&
        install -m 0755 /tmp/minio /usr/local/bin/minio &&
        install -d -m 0755 /data &&
        cat >/usr/local/bin/start-minio.sh <<'SH'
#!/bin/sh
set -eu
export MINIO_ROOT_USER="$${MINIO_ROOT_USER:-MINIO_USER_DEFAULT}"
export MINIO_ROOT_PASSWORD="$${MINIO_ROOT_PASSWORD:-MINIO_PASS_DEFAULT}"
exec /usr/local/bin/minio server /data --address :${var.minio_internal_s3_port} --console-address :${var.minio_internal_console_port}
SH
        sed -i "s/MINIO_USER_DEFAULT/${var.minio_access_key}/" /usr/local/bin/start-minio.sh
        sed -i "s/MINIO_PASS_DEFAULT/${var.minio_secret_key}/" /usr/local/bin/start-minio.sh
        chmod +x /usr/local/bin/start-minio.sh &&
        cat >/etc/systemd/system/minio.service <<'UNIT'
[Unit]
Description=MinIO Server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/start-minio.sh
Restart=on-failure
RestartSec=2s
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
UNIT
        systemctl daemon-reload &&
        systemctl enable --now minio || systemctl restart minio &&
        cat >/usr/local/bin/wait-minio.sh <<'WAIT'
#!/bin/sh
set -eu
i=0
while [ \"$i\" -lt 40 ]; do
  if curl -sf http://127.0.0.1:${var.minio_internal_s3_port}/minio/health/ready >/dev/null 2>&1; then
    exit 0
  fi
  i=$((i+1))
  sleep 1
done
echo 'MinIO failed to become ready. Last logs:' >&2
journalctl -u minio -n 200 --no-pager >&2 || true
exit 1
WAIT
        chmod +x /usr/local/bin/wait-minio.sh &&
        /usr/local/bin/wait-minio.sh
      "
    EOT
  }

  depends_on = [incus_instance.minio]
}

resource "null_resource" "open_firewall" {
  count = var.host_ssh_user == null ? 0 : 1
  triggers = {
    host      = local.host_ssh_address
    port_s3   = tostring(var.s3_port)
    port_cons = tostring(var.console_port)
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -eu
      if [ -z "${coalesce(var.host_ssh_user, "")}" ]; then
        echo "host_ssh_user not set; skipping firewall open"
        exit 0
      fi
      SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p ${var.host_ssh_port}"
      KEY_FILE=""
      if [ -n "${coalesce(var.host_ssh_private_key, "")}" ]; then
        KEY_FILE=$(mktemp)
        printf "%s" "${coalesce(var.host_ssh_private_key, "")}" > "$KEY_FILE"
        chmod 600 "$KEY_FILE"
        SSH_OPTS="$SSH_OPTS -i $KEY_FILE"
      fi
      ssh $SSH_OPTS ${coalesce(var.host_ssh_user, "")}@${local.host_ssh_address} '
        set -eu
        if command -v ufw >/dev/null 2>&1; then
          sudo ufw allow ${var.s3_port}/tcp || true
          sudo ufw allow ${var.console_port}/tcp || true
          exit 0
        fi
        if command -v firewall-cmd >/dev/null 2>&1; then
          sudo firewall-cmd --permanent --add-port=${var.s3_port}/tcp || true
          sudo firewall-cmd --permanent --add-port=${var.console_port}/tcp || true
          sudo firewall-cmd --reload || true
          exit 0
        fi
        if command -v nft >/dev/null 2>&1; then
          sudo nft list tables | grep -q "inet filter" || sudo nft add table inet filter
          sudo nft list chains inet filter | grep -q "input" || sudo nft add chain inet filter input { type filter hook input priority 0; policy accept; }
          sudo nft list ruleset | grep -q "tcp dport ${var.s3_port} accept" || sudo nft add rule inet filter input tcp dport ${var.s3_port} accept
          sudo nft list ruleset | grep -q "tcp dport ${var.console_port} accept" || sudo nft add rule inet filter input tcp dport ${var.console_port} accept
          exit 0
        fi
        if command -v iptables >/dev/null 2>&1; then
          sudo iptables -C INPUT -p tcp --dport ${var.s3_port} -j ACCEPT 2>/dev/null || sudo iptables -I INPUT -p tcp --dport ${var.s3_port} -j ACCEPT
          sudo iptables -C INPUT -p tcp --dport ${var.console_port} -j ACCEPT 2>/dev/null || sudo iptables -I INPUT -p tcp --dport ${var.console_port} -j ACCEPT
          if command -v netfilter-persistent >/dev/null 2>&1; then sudo netfilter-persistent save || true; fi
          exit 0
        fi
        echo "No supported firewall tool found (ufw, firewall-cmd, nft, iptables). Please open ports ${var.s3_port}/${var.console_port} manually."
      '
      if [ -n "$KEY_FILE" ]; then rm -f "$KEY_FILE"; fi
    EOT
  }

  depends_on = [incus_instance.minio]
}

resource "null_resource" "ensure_proxy" {
  triggers = {
    instance_name = incus_instance.minio.name
    s3_port       = tostring(var.s3_port)
    console_port  = tostring(var.console_port)
    project_name  = incus_project.project.name
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -eu
      export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"
      INCUS_CMD=$(command -v incus || which incus || echo "incus")
      $INCUS_CMD remote get-url ${local.remote_name} >/dev/null 2>&1 || $INCUS_CMD remote add ${local.remote_name} ${var.incus_endpoint} --accept-certificate --auth-type tls --token ${var.incus_token} || true
      # Re-add proxy devices to ensure host listeners are active
      $INCUS_CMD --project ${incus_project.project.name} config device remove ${local.remote_name}:${incus_instance.minio.name} s3 || true
      $INCUS_CMD --project ${incus_project.project.name} config device add ${local.remote_name}:${incus_instance.minio.name} s3 proxy listen=tcp:0.0.0.0:${var.s3_port} connect=tcp:127.0.0.1:${var.minio_internal_s3_port} bind=host
      $INCUS_CMD --project ${incus_project.project.name} config device remove ${local.remote_name}:${incus_instance.minio.name} console || true
      $INCUS_CMD --project ${incus_project.project.name} config device add ${local.remote_name}:${incus_instance.minio.name} console proxy listen=tcp:0.0.0.0:${var.console_port} connect=tcp:127.0.0.1:${var.minio_internal_console_port} bind=host
    EOT
  }

  depends_on = [incus_instance.minio, null_resource.setup_minio]
}



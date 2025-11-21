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
    "limits.cpu"     = "1"
    "limits.memory"  = "1GB"
    "user.user-data" = <<-EOF
#cloud-config
package_update: true
packages:
  - curl
  - ca-certificates
runcmd:
  - mkdir -p /usr/local/bin
  - mkdir -p /data
  - curl -fsSL -o /usr/local/bin/minio https://dl.min.io/server/minio/release/linux-amd64/minio
  - chmod 0755 /usr/local/bin/minio
  - sh -lc "MINIO_ROOT_USER='${var.minio_access_key}' MINIO_ROOT_PASSWORD='${var.minio_secret_key}' nohup /usr/local/bin/minio server /data --address :${var.minio_internal_s3_port} --console-address :${var.minio_internal_console_port} >/var/log/minio.log 2>&1 &"
EOF
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



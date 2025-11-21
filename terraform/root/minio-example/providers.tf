locals {
  remote_name = "incus-server-root-${var.project_name}"
}

provider "incus" {
  generate_client_certificates = true
  accept_remote_certificate    = true
  default_remote               = local.remote_name

  remote {
    name    = "local"
    address = "unix://"
  }

  remote {
    name    = local.remote_name
    address = var.incus_endpoint
    token   = var.incus_token
  }
}



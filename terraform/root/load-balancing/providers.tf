provider "incus" {
  generate_client_certificates = true
  accept_remote_certificate    = true
  default_remote               = "incus-server-root"

  remote {
    name    = "local"
    address = "unix://"
  }

  remote {
    name    = "incus-server-root"
    address = var.incus_endpoint
    token   = var.incus_token
  }
}




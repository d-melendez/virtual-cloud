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
    address = "https://138.68.45.47:8443"
    token   = var.incus_token
  }
}


locals {
  app_name        = "Incus UI SSO"
  app_description = "SSO application for Incus UI"

  # Replace these with your Incus UI URLs
  callback_urls = [
    "https://${var.incus_ip_address}/oidc/callback",
    "https://${var.auth0_domain}/login/callback"
  ]

  logout_urls = [
    "https://${var.incus_ip_address}/"
  ]

  web_origins = [
    "https://${var.incus_ip_address}"
  ]

  allowed_origins = []

  grant_types = [
    "authorization_code",
    "refresh_token"
  ]
}

module "incus_auth0_app" {
  source = "./modules/auth0"

  app_name        = local.app_name
  app_description = local.app_description
  callback_urls   = local.callback_urls
  logout_urls     = local.logout_urls
  web_origins     = local.web_origins
  allowed_origins = local.allowed_origins
  grant_types     = local.grant_types

  auth0_domain        = var.auth0_domain
  auth0_client_id     = var.auth0_client_id
  auth0_client_secret = var.auth0_client_secret
}

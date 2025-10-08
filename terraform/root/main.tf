module "incus_auth0_app" {
  source = "./modules/auth0"

  app_name        = var.app_name
  app_description = var.app_description
  callback_urls   = var.callback_urls
  logout_urls     = var.logout_urls
  web_origins     = var.web_origins
  allowed_origins = var.allowed_origins
  grant_types     = var.grant_types

  auth0_domain        = var.auth0_domain
  auth0_client_id     = var.auth0_client_id
  auth0_client_secret = var.auth0_client_secret
}

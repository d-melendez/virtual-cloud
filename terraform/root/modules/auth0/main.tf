resource "auth0_client" "this" {
  name        = var.app_name
  description = var.app_description

  app_type        = "native"
  is_first_party  = true
  oidc_conformant = true
  sso             = true

  callbacks           = var.callback_urls
  allowed_logout_urls = var.logout_urls
  web_origins         = var.web_origins
  allowed_origins     = var.allowed_origins

  grant_types = var.grant_types
}



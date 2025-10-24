output "auth0_application_client_id" {
  description = "Auth0 application (client) ID"
  value       = module.incus_auth0_app.client_id
}

output "auth0_application_domain" {
  description = "Auth0 application domain"
  value       = module.incus_auth0_app.domain
}
output "client_id" {
  description = "Auth0 application (client) ID"
  value       = auth0_client.this.client_id
}

output "domain" {
  description = "Auth0 application domain"
  value       = auth0_client.this.domain
}

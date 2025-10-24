variable "auth0_domain" {
  description = "Auth0 tenant domain, e.g. your-tenant.us.auth0.com"
  type        = string
}

variable "auth0_client_id" {
  description = "Auth0 Management API client ID to manage resources"
  type        = string
}

variable "auth0_client_secret" {
  description = "Auth0 Management API client secret"
  type        = string
  sensitive   = true
}

variable "incus_ip_address" {
  description = "IP address of the Incus server"
  type        = string
}
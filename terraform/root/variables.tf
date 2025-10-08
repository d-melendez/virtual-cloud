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

variable "app_name" {
  description = "Display name for the Incus UI SSO application"
  type        = string
  default     = "Incus UI SSO"
}

variable "app_description" {
  description = "Description for the Incus UI SSO application"
  type        = string
  default     = "SSO application for Incus UI"
}

variable "callback_urls" {
  description = "Allowed callback URLs for Auth0 (redirect URIs)"
  type        = list(string)
}

variable "logout_urls" {
  description = "Allowed logout redirect URLs"
  type        = list(string)
}

variable "web_origins" {
  description = "Allowed web origins for CORS/PKCE flows"
  type        = list(string)
  default     = []
}

variable "allowed_origins" {
  description = "Additional allowed origins for cross-origin authentication"
  type        = list(string)
  default     = []
}

variable "grant_types" {
  description = "OAuth grant types enabled for the application"
  type        = list(string)
  default = [
    "authorization_code",
    "refresh_token"
  ]
}



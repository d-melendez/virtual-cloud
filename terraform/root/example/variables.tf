variable "incus_token" {
  description = "Incus authentication token"
  type        = string
  sensitive   = true
}

variable "incus_endpoint" {
  description = "Incus server endpoint (e.g., https://example.com:8443)"
  type        = string
  default     = "https://localhost:8443"
}

variable "project_name" {
  description = "Name of the Incus project to create"
  type        = string
  default     = "example-project"
}

variable "instance_name" {
  description = "Name of the instance to create"
  type        = string
  default     = "example-instance"
}

variable "instance_image" {
  description = "Image to use for the instance (e.g., images:ubuntu/24.04)"
  type        = string
  default     = "images:ubuntu/24.04"
}

variable "instance_type" {
  description = "Type of instance (container or virtual-machine)"
  type        = string
  default     = "container"
}

variable "storage_pool" {
  description = "Storage pool name to use for the instance root disk"
  type        = string
  default     = "default"
}


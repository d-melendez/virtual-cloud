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
  default     = "load-balancing-project"
}

variable "instance_image" {
  description = "Image to use for the instances (e.g., images:ubuntu/24.04)"
  type        = string
  default     = "images:ubuntu/22.04"
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

variable "http_port" {
  description = "HTTP port for the load balancer"
  type        = number
  default     = 8080
}

variable "listen_address" {
  description = "Listen address for the load balancer (e.g., 10.10.10.200)"
  type        = string
  default     = "10.10.10.200"
}

variable "bridge_ipv4_cidr" {
  description = "IPv4 address and subnet for the Incus bridge network"
  type        = string
  default     = null
}

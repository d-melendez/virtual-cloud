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
  default     = "minio-example"
}

variable "instance_image" {
  description = "Image to use for the instance (e.g., images:ubuntu/22.04)"
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

variable "s3_port" {
  description = "Host port to expose MinIO S3 API"
  type        = number
  default     = 9000
}

variable "console_port" {
  description = "Host port to expose MinIO Console"
  type        = number
  default     = 9001
}

variable "minio_internal_s3_port" {
  description = "Container-internal MinIO S3 port"
  type        = number
  default     = 9000
}

variable "minio_internal_console_port" {
  description = "Container-internal MinIO Console port"
  type        = number
  default     = 9001
}

variable "bridge_ipv4_cidr" {
  description = "IPv4 address and subnet for the Incus bridge network"
  type        = string
  default     = null
}

variable "minio_access_key" {
  description = "MinIO root access key (MINIO_ROOT_USER)"
  type        = string
  sensitive   = true
}

variable "minio_secret_key" {
  description = "MinIO root secret key (MINIO_ROOT_PASSWORD)"
  type        = string
  sensitive   = true
}

variable "host_ssh_user" {
  description = "SSH user for Incus host (optional; if unset, firewall opening is skipped)"
  type        = string
  default     = null
}

variable "host_ssh_address" {
  description = "SSH address/IP for Incus host (optional; defaults to parsed incus_endpoint host)"
  type        = string
  default     = null
}

variable "host_ssh_port" {
  description = "SSH port for Incus host"
  type        = number
  default     = 22
}

variable "host_ssh_private_key" {
  description = "PEM private key for SSH (optional; if unset, default SSH identity is used)"
  type        = string
  sensitive   = true
  default     = null
}



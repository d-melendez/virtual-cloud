output "project_name" {
  description = "Name of the created Incus project"
  value       = incus_project.project.name
}

output "minio_instance_ip" {
  description = "IPv4 address of the MinIO instance"
  value       = incus_instance.minio.ipv4_address
}

output "s3_endpoint" {
  description = "S3 API endpoint URL"
  value       = "http://<incus-host>:${var.s3_port}"
}

output "console_url" {
  description = "MinIO Console URL"
  value       = "http://<incus-host>:${var.console_port}"
}

output "minio_access_key" {
  description = "MinIO root access key"
  value       = var.minio_access_key
  sensitive   = true
}



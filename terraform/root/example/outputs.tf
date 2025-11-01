output "project_name" {
  description = "Name of the created Incus project"
  value       = incus_project.project.name
}

output "instance_name" {
  description = "Name of the created instance"
  value       = incus_instance.instance.name
}

output "instance_status" {
  description = "Current status of the instance"
  value       = incus_instance.instance.status
}

output "instance_ipv4" {
  description = "IPv4 address of the instance"
  value       = incus_instance.instance.ipv4_address
}


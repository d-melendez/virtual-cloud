output "project_name" {
  description = "Name of the created Incus project"
  value       = incus_project.project.name
}

output "load_balancer_listen_address" {
  description = "Listen address of the load balancer"
  value       = "Incus host IP (see var.incus_endpoint)"
}

output "load_balancer_port" {
  description = "HTTP port for the load balancer"
  value       = var.http_port
}

output "web_instance_ips" {
  description = "IPv4 addresses of the web instances"
  value = {
    instance_1 = incus_instance.web_instances[0].ipv4_address
    instance_2 = incus_instance.web_instances[1].ipv4_address
    instance_3 = incus_instance.web_instances[2].ipv4_address
  }
}

output "access_url" {
  description = "URL to access the load balancer"
  value       = "http://<incus-host>:${var.http_port}"
}

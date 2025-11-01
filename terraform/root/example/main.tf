resource "incus_project" "project" {
  name        = var.project_name
  description = "Example Incus project created with Terraform"
  remote      = "incus-server-root"
}

resource "incus_profile" "profile" {
  name    = "default"
  project = incus_project.project.name
  remote  = "incus-server-root"

  device {
    name = "root"
    type = "disk"
    properties = {
      path = "/"
      pool = var.storage_pool
    }
  }

  depends_on = [incus_project.project]
}

resource "incus_instance" "instance" {
  name    = var.instance_name
  image   = var.instance_image
  type    = var.instance_type
  project = incus_project.project.name
  remote  = "incus-server-root"
  profiles = [incus_profile.profile.name]

  config = {
    "limits.cpu"    = "2"
    "limits.memory" = "2GB"
  }

  depends_on = [incus_project.project, incus_profile.profile]
}


data "openstack_images_image_v2" "img" {
  name        = var.image_name
  most_recent = true
}

data "openstack_compute_flavor_v2" "flv" {
  name = var.flavor_name
}

data "openstack_networking_network_v2" "tenant_net" {
  name = var.tenant_network_name
}

resource "openstack_compute_keypair_v2" "kp" {
  name       = "tf-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "openstack_networking_secgroup_v2" "ssh_icmp" {
  name        = "ssh-icmp"
  description = "Allow SSH and ping"
}

resource "openstack_networking_secgroup_rule_v2" "ssh" {
  security_group_id = openstack_networking_secgroup_v2.ssh_icmp.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_rule_v2" "icmp" {
  security_group_id = openstack_networking_secgroup_v2.ssh_icmp.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "openstack_compute_instance_v2" "vm" {
  name            = "tf-demo"
  image_id        = data.openstack_images_image_v2.img.id
  flavor_id       = data.openstack_compute_flavor_v2.flv.id
  key_pair        = openstack_compute_keypair_v2.kp.name
  security_groups = [openstack_networking_secgroup_v2.ssh_icmp.name]

  network {
    uuid = data.openstack_networking_network_v2.tenant_net.id
  }
}



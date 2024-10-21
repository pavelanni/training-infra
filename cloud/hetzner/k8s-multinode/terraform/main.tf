terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.48.1"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Generate the admin SSH key
resource "tls_private_key" "admin_ssh_key" {
  algorithm = "ED25519"
}

# Save the admin SSH key in a local file
resource "local_file" "admin_ssh_key" {
  filename        = "./output/${var.deployment_name}-admin-private-key"
  content         = tls_private_key.admin_ssh_key.private_key_openssh
  file_permission = "0600"
}

# The admin SSH key to upload to the cloud
resource "hcloud_ssh_key" "admin" {
  name       = "${var.deployment_name}-admin-public-key"
  public_key = tls_private_key.admin_ssh_key.public_key_openssh
}

# Create the worker nodes
resource "hcloud_server" "nodes" {
  count       = var.node_count
  name        = format("%s-node-%02d", var.deployment_name, count.index + 1)
  server_type = var.node_type
  image       = var.hcloud_os_type
  location    = var.hcloud_location

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
  ssh_keys = [
    hcloud_ssh_key.admin.id
  ]
  user_data = templatefile("./templates/cloud-init-node.tmpl", {
    user             = var.user
    hostname         = format("node-%02d.%s", count.index + 1, var.deployment_name)
    domain_name      = var.domain_name
    certbot_email    = var.certbot_email
    admin_public_key = tls_private_key.admin_ssh_key.public_key_openssh
  })
}

# Create the DNS records for the nodes
resource "cloudflare_record" "nodes" {
  count   = var.node_count
  zone_id = var.cloudflare_zone_id
  name    = format("node-%02d.%s", count.index + 1, var.deployment_name)
  content = hcloud_server.nodes[count.index].ipv4_address
  type    = "A"
  proxied = false
  ttl     = 1
}


# Create the control plane node
resource "hcloud_server" "control_plane" {
  name        = "${var.deployment_name}-cp"
  server_type = var.control_plane_type
  image       = var.hcloud_os_type
  location    = var.hcloud_location
  ssh_keys = [
    hcloud_ssh_key.admin.id
  ]
  user_data = templatefile("./templates/cloud-init-cp.tmpl", {
    user             = var.user
    hostname         = format("cp.%s", var.deployment_name)
    domain_name      = var.domain_name
    certbot_email    = var.certbot_email
    admin_public_key = tls_private_key.admin_ssh_key.public_key_openssh
  })
}

# Create the DNS record for the control plane node
resource "cloudflare_record" "control_plane" {
  zone_id = var.cloudflare_zone_id
  name    = format("cp.%s", var.deployment_name)
  content = hcloud_server.control_plane.ipv4_address
  type    = "A"
  proxied = false
  ttl     = 1
}

# Create the volumes for the nodes
resource "hcloud_volume" "storage" {
  count    = var.node_count * 4
  name     = format("%s-volume-%02d", var.deployment_name, count.index + 1)
  size     = var.volume_size
  location = var.hcloud_location
  format   = "xfs"
}

# Attach the volumes to the nodes
resource "hcloud_volume_attachment" "attachments" {
  count     = var.node_count * 4
  volume_id = hcloud_volume.storage[count.index].id
  server_id = hcloud_server.nodes[floor(count.index / 4)].id
  automount = false
}


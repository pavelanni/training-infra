# Configure the Hetzner Cloud Provider
terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.48.0"
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

# Generate SSH key
resource "tls_private_key" "gen_ssh_key" {
  count     = var.student_count
  algorithm = "ED25519"
}

# Generate the admin SSH key
resource "tls_private_key" "admin_ssh_key" {
  algorithm = "ED25519"
}

# Save the private SSH key in a local file
resource "local_file" "ssh_key" {
  count           = var.student_count
  filename        = format("./output/%s-%02d-private-key", var.deployment_name, count.index + 1)
  content         = tls_private_key.gen_ssh_key[count.index].private_key_openssh
  file_permission = "0600"
}

# Save the admin SSH key in a local file
resource "local_file" "admin_ssh_key" {
  filename        = "./output/${var.deployment_name}-admin-private-key"
  content         = tls_private_key.admin_ssh_key.private_key_openssh
  file_permission = "0600"
}


# The SSH key to upload to the cloud
resource "hcloud_ssh_key" "default" {
  count      = var.student_count
  name       = format("%s-%02d-public-key", var.deployment_name, count.index + 1)
  public_key = tls_private_key.gen_ssh_key[count.index].public_key_openssh
}

# The admin SSH key to upload to the cloud
resource "hcloud_ssh_key" "admin" {
  name       = "${var.deployment_name}-admin-public-key"
  public_key = tls_private_key.admin_ssh_key.public_key_openssh
}

# Create the server
resource "hcloud_server" "miniolabs_server" {
  count       = var.student_count
  name        = format("%s-%02d", var.deployment_name, count.index + 1)
  image       = var.hcloud_os_type
  server_type = var.hcloud_server_type
  location    = var.hcloud_location
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
  ssh_keys = [
    hcloud_ssh_key.default[count.index].id,
    hcloud_ssh_key.admin.id
  ]
  user_data = templatefile("./assets/templates/cloud-init.tmpl", {
    user                 = var.user
    total_minutes        = var.instance_lifetime_minutes
    minio_ssh_public_key = tls_private_key.gen_ssh_key[count.index].public_key_openssh
    hostname             = format("%s-%02d", var.deployment_name, count.index + 1)
    domain_name          = var.domain_name
    certbot_email        = var.certbot_email
  })
}

# Create the volumes
resource "hcloud_volume" "disk" {
  count = var.student_count * var.hcloud_volume_count
  name = format(
    "%s-%02d-%02d",
    var.deployment_name,
    floor(count.index / var.hcloud_volume_count) + 1,
    count.index % var.hcloud_volume_count + 1
  )
  size     = var.hcloud_volume_size
  format   = "xfs"
  location = var.hcloud_location
}

# Attach the volumes
resource "hcloud_volume_attachment" "disk" {
  count     = var.student_count * var.hcloud_volume_count
  server_id = hcloud_server.miniolabs_server[floor(count.index / var.hcloud_volume_count)].id
  volume_id = hcloud_volume.disk[count.index].id
}

resource "cloudflare_record" "miniolabs" {
  count   = var.student_count
  zone_id = var.cloudflare_zone_id
  name    = format("%s-%02d", var.deployment_name, count.index + 1)
  content = hcloud_server.miniolabs_server[count.index].ipv4_address
  type    = "A"
  proxied = false
  ttl     = 1
}

# Wait until cloud-init is done
resource "null_resource" "cloud_init_wait" {
  count = var.student_count
  connection {
    host        = hcloud_server.miniolabs_server[count.index].ipv4_address
    type        = "ssh"
    user        = "root"
    private_key = tls_private_key.gen_ssh_key[count.index].private_key_openssh
  }
  provisioner "remote-exec" {
    # we need this because cloud-init now returns 2 when there are warnings
    # see here: https://docs.cloud-init.io/en/latest/explanation/return_codes.html
    # This is my old inline
    #inline = ["cloud-init status --wait ; status=$? ; if [ $status -eq 0 ] || [ $status -eq 2 ]; then exit 0; else exit 1; fi"]
    # This one is to address reboots problem
    inline = [
      "#!/bin/bash",
      "timeout=600", # 10 minutes timeout
      "end=$(($(date +%s) + timeout))",
      "while [ $(date +%s) -lt $end ]; do",
      "  cloud-init status",
      "  status=$?",
      "  if [ $status -eq 0 ] || [ $status -eq 2 ]; then",
      "    echo \"Cloud-init finished successfully (status: $status)\"",
      "    exit 0",
      "  fi",
      "  echo \"Waiting for cloud-init to finish... (last status: $status)\"",
      "  sleep 10",
      "done",
      "echo 'Timeout waiting for cloud-init'",
      "exit 1"
    ]
  }
  depends_on = [hcloud_server.miniolabs_server]
}

# Output the IP
output "ip_address" {
  value = {
    for i in hcloud_server.miniolabs_server : i.name => i.ipv4_address
  }
}

# Save the IP address in a local file
resource "local_file" "ip_address" {
  count           = var.student_count
  filename        = format("./output/%s-%02d-ip-address", var.deployment_name, count.index + 1)
  content         = hcloud_server.miniolabs_server[count.index].ipv4_address
  file_permission = "0600"
}

# Output the SSH key location
output "ssh_key" {
  value = {
  for i in hcloud_ssh_key.default : i.name => i.public_key }
}

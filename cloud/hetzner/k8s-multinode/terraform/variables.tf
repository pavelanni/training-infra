# General User variables
variable "deployment_name" { default = "cluster-01" }
variable "domain_name" { default = "miniolabs.net" }
variable "certbot_email" { default = "pavel.anni@gmail.com" }
variable "user" { default = "pavel" }
variable "node_count" { default = 4 }
variable "node_type" { default = "cx22" }
variable "control_plane_count" { default = 1 }
variable "control_plane_type" { default = "cx22" }
variable "volume_size" { default = 10 }
# Hetzner (hcloud) variables
variable "hcloud_token" {}
variable "hcloud_location" { default = "fsn1" }
variable "hcloud_os_type" { default = "ubuntu-24.04" }

# Cloudflare variables
variable "cloudflare_api_token" {}
variable "cloudflare_zone_id" {}
variable "cloudflare_email" {}

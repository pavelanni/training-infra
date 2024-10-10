# General User variables
variable "deployment_name" { default = "docs" }
variable "domain_name" { default = "miniolabs.net" }
variable "certbot_email" { default = "pavel.anni@gmail.com" }
variable "user" { default = "pavel" }


# Hetzner (hcloud) variables
variable "hcloud_token" {}
variable "hcloud_location" { default = "fsn1" }
variable "hcloud_server_type" { default = "cpx41" }
variable "hcloud_os_type" { default = "ubuntu-24.04" }

# Cloudflare variables
variable "cloudflare_api_token" {}
variable "cloudflare_zone_id" {}
variable "cloudflare_email" {}

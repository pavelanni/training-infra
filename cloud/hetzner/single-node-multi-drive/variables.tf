# General User variables
variable "deployment_name" { default = "miniolab" }
variable "domain_name" { default = "miniolabs.net" }
variable "certbot_email" { default = "pavel.anni@gmail.com" }
variable "user" { default = "minio" }
variable "student_count" { default = "4" }
variable "instance_lifetime_minutes" { default = "60" }


# Hetzner (hcloud) variables
variable "hcloud_token" {}
variable "hcloud_location" { default = "fsn1" }
variable "hcloud_server_type" { default = "cx22" }
variable "hcloud_os_type" { default = "ubuntu-24.04" }
variable "hcloud_volume_size" { default = "10" }
variable "hcloud_volume_count" { default = "4" }

# Cloudflare variables
variable "cloudflare_api_token" {}
variable "cloudflare_zone_id" {}
variable "cloudflare_email" {}

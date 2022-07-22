terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
}

variable "hcloud_token" {
  type        = string
  description = "Hetzner API token for terraform"
  sensitive   = true
}

provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_network" "kubernetes" {
  name     = "kubernetes"
  ip_range = "10.0.0.0/8"
}

resource "hcloud_network_subnet" "cni" {
  type         = "cloud"
  network_id   = hcloud_network.kubernetes.id
  network_zone = "eu-central"
  ip_range     = "10.0.0.0/16"
}

output "network_id" {
  value = hcloud_network.kubernetes.id
}

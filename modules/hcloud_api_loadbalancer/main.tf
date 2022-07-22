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

resource "hcloud_load_balancer" "controlplane" {
  name = "controlplane"
  labels = {
    type = "controlplane"
  }
  load_balancer_type = "lb11"
  network_zone       = "eu-central"
}

resource "hcloud_load_balancer_service" "controlplane" {
  load_balancer_id = hcloud_load_balancer.controlplane.id

  listen_port      = 6443
  destination_port = 6443
  protocol         = "tcp"
}

resource "hcloud_load_balancer_target" "controlplane" {
  load_balancer_id = hcloud_load_balancer.controlplane.id

  type           = "label_selector"
  label_selector = "type=controlplane"
}

output "ipv4" {
  value = hcloud_load_balancer.controlplane.ipv4
}

output "ipv6" {
  value = hcloud_load_balancer.controlplane.ipv6
}

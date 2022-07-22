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

variable "node_creation_depends_on" {
  type        = any
  description = "Wait for other ressources"
}

data "hcloud_image" "talos" {
  with_selector = "type=infra,os=talos"
  depends_on    = [var.node_creation_depends_on]
}

variable "controlplane_configuration" {
  type        = string
  description = "Control plane configuration"
}

variable "worker_configuration" {
  type        = string
  description = "Worker plane configuration"
}

variable "network_id" {
  type        = string
  description = "Hetzner network id"
}

resource "hcloud_server" "control-plane-1" {
  name        = "talos-control-plane-1"
  image       = data.hcloud_image.talos.id
  server_type = "cx11"
  location    = "hel1"
  labels = {
    "type" = "controlplane"
  }
  user_data = var.controlplane_configuration
  network {
    network_id = var.network_id
    ip         = "10.0.1.1"
  }
}

resource "hcloud_server" "control-plane-2" {
  name        = "talos-control-plane-2"
  image       = data.hcloud_image.talos.id
  server_type = "cx11"
  location    = "nbg1"
  labels = {
    "type" = "controlplane"
  }
  user_data = var.controlplane_configuration
  network {
    network_id = var.network_id
    ip         = "10.0.1.2"
  }
}

resource "hcloud_server" "control-plane-3" {
  name        = "talos-control-plane-3"
  image       = data.hcloud_image.talos.id
  server_type = "cx11"
  location    = "fsn1"
  labels = {
    "type" = "controlplane"
  }
  user_data = var.controlplane_configuration
  network {
    network_id = var.network_id
    ip         = "10.0.1.3"
  }
}

resource "hcloud_server" "worker-1" {
  name        = "talos-worker-1"
  image       = data.hcloud_image.talos.id
  server_type = "cx21"
  location    = "hel1"
  labels = {
    "type" = "worker"
  }
  user_data = var.worker_configuration
  network {
    network_id = var.network_id
    ip         = "10.0.2.1"
  }
}

resource "hcloud_server" "worker-2" {
  name        = "talos-worker-2"
  image       = data.hcloud_image.talos.id
  server_type = "cx21"
  location    = "nbg1"
  labels = {
    "type" = "worker"
  }
  user_data = var.worker_configuration
  network {
    network_id = var.network_id
    ip         = "10.0.2.2"
  }
}

resource "hcloud_server" "worker-3" {
  name        = "talos-worker-3"
  image       = data.hcloud_image.talos.id
  server_type = "cx21"
  location    = "fsn1"
  labels = {
    "type" = "worker"
  }
  user_data = var.worker_configuration
  network {
    network_id = var.network_id
    ip         = "10.0.2.3"
  }
}

resource "null_resource" "configure-talos-config" {
  provisioner "local-exec" {
    command = "talosctl config --talosconfig ${path.root}/generated/configs/talosconfig node ${hcloud_server.control-plane-1.ipv4_address}"
  }

  provisioner "local-exec" {
    command = "talosctl config --talosconfig ${path.root}/generated/configs/talosconfig endpoint ${hcloud_server.control-plane-1.ipv4_address}"
  }
}

output "config_generation_status" {
  value = null_resource.configure-talos-config
}

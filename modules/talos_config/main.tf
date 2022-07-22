terraform {
  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = "0.1.0-alpha.1"
    }
  }
}

variable "controlplane_host" {
  type        = string
  description = "Fully qualified domaine name of the controlplane host"
}

variable "talos_version" {
  type        = string
  description = "TalOS version"
  default     = "v1.1.1"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version"
  default     = "1.24.4"
}

data "local_file" "common_config_patches" {
  filename = "${path.module}/patches/common_config_patches.json"
}

resource "talos_machine_configuration" "config" {
  cluster_name          = "own-kube"
  cluster_endpoint      = "https://${var.controlplane_host}:6443"
  common_config_patches = [data.local_file.common_config_patches.content]
}

resource "local_file" "talosconfig" {
  filename = "${path.root}/generated/configs/talosconfig.tmp"
  content  = talos_machine_configuration.config.talosconfig
}

resource "null_resource" "copy-talosconfig" {
  provisioner "local-exec" {
    command = "cp ${path.root}/generated/configs/talosconfig.tmp ${path.root}/generated/configs/talosconfig"
  }

  depends_on = [
    local_file.talosconfig
  ]
}

resource "local_file" "controlplane_configuration" {
  filename = "${path.root}/generated/configs/controlplane.yaml"
  content  = talos_machine_configuration.config.control_plane_machine_configuration
}

resource "local_file" "worker_configuration" {
  filename = "${path.root}/generated/configs/worker.yaml"
  content  = talos_machine_configuration.config.worker_machine_configuration
}

resource "null_resource" "verification-controlplane" {
  provisioner "local-exec" {
    command = "talosctl validate --config ${local_file.controlplane_configuration.filename} --mode cloud"
  }
}

resource "null_resource" "verification-worker" {
  provisioner "local-exec" {
    command = "talosctl validate --config ${local_file.worker_configuration.filename} --mode cloud"
  }
}

output "controlplane_configuration" {
  value = local_file.controlplane_configuration.content
}

output "worker_configuration" {
  value = local_file.worker_configuration.content
}

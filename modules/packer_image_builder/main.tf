terraform {
  required_providers {
    packer = {
      source = "toowoxx/packer"
    }
  }
}

variable "hcloud_token" {
  type        = string
  description = "Hetzner API token for packer"
  sensitive   = true
}


data "packer_version" "version" {}

data "packer_files" "talos_pkr_files" {
  file = "${path.root}/templates/packer/talos.pkr.hcl"
}

resource "packer_image" "talos" {
  file = data.packer_files.talos_pkr_files.file

  variables = {
    hcloud_token = var.hcloud_token
  }

  triggers = {
    packer_version = data.packer_version.version.version
    files_hash     = data.packer_files.talos_pkr_files.files_hash
  }
}

output "version" {
  value = data.packer_version.version.version
}

output "build_id" {
  value = packer_image.talos.build_uuid
}


variable "bootstrap_depends_on" {
  type        = any
  description = "Wait for other ressources"
}

resource "time_sleep" "startup_time" {
  create_duration = "1m"

  depends_on = [
    var.bootstrap_depends_on
  ]
}


resource "null_resource" "boostrap" {
  provisioner "local-exec" {
    command = "talosctl bootstrap --talosconfig ${path.root}/generated/configs/talosconfig"
  }

  depends_on = [
    time_sleep.startup_time
  ]
}


resource "time_sleep" "bootstrap_time" {
  create_duration = "3m"

  depends_on = [
    null_resource.boostrap
  ]
}

resource "null_resource" "generate-kubeconfig" {
  provisioner "local-exec" {
    command = "talosctl kubeconfig --talosconfig ${path.root}/generated/configs/talosconfig ${path.root}/generated/configs/"
  }

  depends_on = [
    time_sleep.bootstrap_time
  ]
}

output "kubernetes_config_path" {
  value = "${path.root}/generated/configs/kubeconfig"

  depends_on = [
    null_resource.generate-kubeconfig
  ]
}

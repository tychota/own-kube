module "packer_image_builder" {
  source       = "./modules/packer_image_builder"
  hcloud_token = var.hcloud_token
}

module "hcloud_api_loadbalancer" {
  source       = "./modules/hcloud_api_loadbalancer"
  hcloud_token = var.hcloud_token
}

module "ovh_api_loadbalancer_dns" {
  source                 = "./modules/ovh_api_loadbalancer_dns"
  ovh_application_key    = var.ovh_application_key
  ovh_application_secret = var.ovh_application_secret
  ovh_consumer_key       = var.ovh_consumer_key
  ipv4                   = module.hcloud_api_loadbalancer.ipv4
  ipv6                   = module.hcloud_api_loadbalancer.ipv6
}

module "talos_config" {
  source            = "./modules/talos_config"
  controlplane_host = module.ovh_api_loadbalancer_dns.controlplane_host
}


module "hcloud_cni_network" {
  source       = "./modules/hcloud_cni_network"
  hcloud_token = var.hcloud_token
}

module "hcloud_nodes" {
  source = "./modules/hcloud_nodes"

  hcloud_token = var.hcloud_token

  node_creation_depends_on = [module.packer_image_builder.build_id]

  controlplane_configuration = module.talos_config.controlplane_configuration
  worker_configuration       = module.talos_config.worker_configuration

  network_id = module.hcloud_cni_network.network_id
}

module "talos_bootstrap" {
  source               = "./modules/talos_bootstrap"
  bootstrap_depends_on = [module.hcloud_nodes.config_generation_status]
}
module "kubernetes_cni" {
  source                 = "./modules/kubernetes_cni"
  kubernetes_config_path = module.talos_bootstrap.kubernetes_config_path
  apiserver_host         = module.ovh_api_loadbalancer_dns.controlplane_host
}

module "kubernetes_hcloud_controller_manager" {
  source                 = "./modules/kubernetes_hcloud_controller_manager"
  kubernetes_config_path = module.talos_bootstrap.kubernetes_config_path
  hcloud_token           = var.hcloud_token
  hcloud_network         = module.hcloud_cni_network.network_id
}

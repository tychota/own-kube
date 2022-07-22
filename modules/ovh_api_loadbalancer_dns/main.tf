terraform {
  required_providers {
    ovh = {
      source = "ovh/ovh"
    }
  }
}

variable "ovh_application_key" {
  type        = string
  description = "OVH application key for terraform"
}

variable "ovh_application_secret" {
  type        = string
  description = "OVH application secret for terraform"
  sensitive   = true
}

variable "ovh_consumer_key" {
  type        = string
  description = "OVH consumer key for terraform"
  sensitive   = true
}

provider "ovh" {
  endpoint           = "ovh-eu"
  application_key    = var.ovh_application_key
  application_secret = var.ovh_application_secret
  consumer_key       = var.ovh_consumer_key
}

variable "zone" {
  type        = string
  description = "controlplane zone"
  default     = "tycho.cloud"
}

variable "subdomain" {
  type        = string
  description = "controlplane subdomain"
  default     = "apiserver.ok-admin"
}

variable "ipv4" {
  type        = string
  description = "controlplane ipv4"
}

variable "ipv6" {
  type        = string
  description = "controlplane ipv6"
}

resource "ovh_domain_zone_record" "controlplane-A" {
  zone      = var.zone
  subdomain = var.subdomain
  fieldtype = "A"
  ttl       = "60"
  target    = var.ipv4
}

resource "ovh_domain_zone_record" "controlplane-AAAA" {
  zone      = var.zone
  subdomain = var.subdomain
  fieldtype = "AAAA"
  ttl       = "60"
  target    = var.ipv6
}

output "controlplane_host" {
  value = "${ovh_domain_zone_record.controlplane-A.subdomain}.${ovh_domain_zone_record.controlplane-A.zone}"
}

variable "hcloud_token" {
  type        = string
  description = "Hetzner API token"
  sensitive   = true
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

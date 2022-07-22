terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.12.1"
    }
  }
}


variable "kubernetes_config_path" {
  type        = string
  description = "Path for kubeconfig file"
}

provider "kubernetes" {
  config_path = var.kubernetes_config_path
}

resource "kubernetes_service_account" "cloud-controller-manager" {
  metadata {
    name      = "cloud-controller-manager"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "cloud-controller-manager" {
  metadata {
    name = "system:cloud-controller-manager"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    namespace = "kube-system"
    name      = "cloud-controller-manager"
  }
}

variable "hcloud_token" {
  type        = string
  description = "Hetzner API token for terraform"
  sensitive   = true
}

variable "hcloud_network" {
  type        = string
  description = "Hetzner network for cilium"
}

resource "kubernetes_secret" "cloud-controller-manager" {
  metadata {
    name      = "hcloud"
    namespace = "kube-system"
  }
  data = {
    token   = var.hcloud_token
    network = var.hcloud_network
  }
}

resource "kubernetes_deployment" "cloud-controller-manager" {
  metadata {
    name      = "hcloud-cloud-controller-manager"
    namespace = "kube-system"
  }
  spec {
    replicas               = 1
    revision_history_limit = 2
    selector {
      match_labels = {
        app = "hcloud-cloud-controller-manager"
      }
    }
    template {
      metadata {
        labels = {
          app = "hcloud-cloud-controller-manager"
        }
        annotations = {
          "scheduler.alpha.kubernetes.io/critical-pod" = ""
        }
      }
      spec {
        service_account_name = "cloud-controller-manager"
        dns_policy           = "Default"
        toleration {
          key    = "node.cloudprovider.kubernetes.io/uninitialized"
          value  = "true"
          effect = "NoSchedule"
        }
        toleration {
          key      = "CriticalAddonsOnly"
          operator = "Exists"
        }
        toleration {
          key      = "node-role.kubernetes.io/master"
          effect   = "NoSchedule"
          operator = "Exists"
        }
        toleration {
          key      = "node-role.kubernetes.io/control-plane"
          effect   = "NoSchedule"
          operator = "Exists"
        }
        toleration {
          key    = "node.kubernetes.io/not-ready"
          effect = "NoSchedule"
        }
        host_network = true
        container {
          image = "hetznercloud/hcloud-cloud-controller-manager:v1.12.1"
          name  = "hcloud-cloud-controller-manager"
          command = [
            "/bin/hcloud-cloud-controller-manager",
            "--cloud-provider=hcloud",
            "--leader-elect=false",
            "--allow-untagged-cloud",
            "--allocate-node-cidrs=true",
            "--cluster-cidr=10.244.0.0/16"
          ]
          resources {
            requests = {
              cpu    = "100m"
              memory = "50Mi"
            }
          }

          env {
            name = "NODE_NAME"
            value_from {
              field_ref {
                field_path = "spec.nodeName"
              }
            }
          }
          env {
            name = "HCLOUD_TOKEN"
            value_from {
              secret_key_ref {
                name = "hcloud"
                key  = "token"
              }
            }
          }
          env {
            name = "HCLOUD_NETWORK"
            value_from {
              secret_key_ref {
                name = "hcloud"
                key  = "network"
              }
            }
          }
        }
      }
    }
  }
}

terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "2.6.0"
    }
  }
}

variable "kubernetes_config_path" {
  type = string
}

provider "helm" {
  kubernetes {
    config_path = var.kubernetes_config_path
  }
}

variable "apiserver_host" {
  type        = string
  description = "Kubernetes apiserver host"
  sensitive   = true
}

variable "apiserver_port" {
  type        = string
  description = "Kubernetes apiserver port"
  default     = 6443
}

resource "helm_release" "cilium" {
  name = "cilium"

  chart = "https://github.com/cilium/charts/raw/master/cilium-1.12.0.tgz"

  namespace = "kube-system"

  # The Kubernetes host-scope IPAM mode is enabled with ipam: kubernetes and delegates the address allocation to each individual node in the cluster. 
  # IPs are allocated out of the PodCIDR range associated to each node by Kubernetes.
  # https://docs.cilium.io/en/stable/concepts/networking/ipam/kubernetes/
  # Note: This looks like a requirements from talos itself https://www.talos.dev/v1.1/kubernetes-guides/network/deploying-cilium/
  set {
    name  = "ipam.mode"
    value = "kubernetes"
  }

  # This will install Cilium as a CNI plugin with the eBPF kube-proxy replacement to implement handling of Kubernetes services of type 
  # ClusterIP, NodePort, LoadBalancer and services with externalIPs. As well, the eBPF kube-proxy replacement also supports hostPort 
  # for containers such that using portmap is not necessary anymore.
  # https://docs.cilium.io/en/stable/gettingstarted/kubeproxy-free
  set {
    name  = "kubeProxyReplacement"
    value = "strict"
  }
  set {
    name  = "k8sServiceHost"
    value = var.apiserver_host
  }
  set {
    name  = "k8sServicePort"
    value = var.apiserver_port
  }

  # Cilium’s eBPF kube-proxy replacement supports consistent hashing by implementing a variant of The Maglev paper hashing in its 
  # load balancer for backend selection. This improves resiliency in case of failures. As well, it provides better load balancing
  # properties since Nodes added to the cluster will make consistent backend selection throughout the cluster for a given 5-tuple
  # without having to synchronize state with the other Nodes. Similarly, upon backend removal the backend lookup tables are 
  # reprogrammed with minimal disruption for unrelated backends (at most 1% difference in the reassignments) for the given service.
  # https://docs.cilium.io/en/stable/gettingstarted/kubeproxy-free/#maglev-consistent-hashing-beta
  set {
    name  = "loadBalancer.algorithm"
    value = "maglev"
  }

  # The native routing datapath is enabled with tunnel: disabled and enables the native packet forwarding mode. The native packet 
  # forwarding mode leverages the routing capabilities of the network Cilium runs on instead of performing encapsulation.
  # In native routing mode, Cilium will delegate all packets which are not addressed to another local endpoint to the routing subsystem
  # of the Linux kernel. This means that the packet will be routed as if a local process would have emitted the packet. As a result, 
  # the network connecting the cluster nodes must be capable of routing PodCIDRs.
  # https://docs.cilium.io/en/stable/concepts/networking/routing/#native-routing
  # This allows integration with hetzner cloud https://github.com/hetznercloud/hcloud-cloud-controller-manager/blob/main/docs/deploy_with_networks.md
  set {
    name  = "tunnel"
    value = "disabled"
  }
  set {
    name  = "ipv4NativeRoutingCIDR"
    value = "10.0.0.0/8"
  }

  # Cilium has built-in support for accelerating NodePort, LoadBalancer services and services with externalIPs for the case where 
  # the arriving request needs to be forwarded and the backend is located on a remote node. This feature was introduced in Cilium 
  # version 1.8 at the XDP (eXpress Data Path) layer where eBPF is operating directly in the networking driver instead of a higher layer.
  # https://docs.cilium.io/en/stable/gettingstarted/kubeproxy-free/#loadbalancer-nodeport-xdp-acceleration

  # set {
  #   name  = "autoDirectNodeRoutes"
  #   value = "true"
  # }

  # set {
  #   name  = "loadBalancer.acceleration"
  #   value = "native"
  # }

  # Cilium also supports a hybrid DSR and SNAT mode, that is, DSR is performed for TCP and SNAT for UDP connections. This removes
  # the need for manual MTU changes in the network while still benefiting from the latency improvements through the removed extra
  # hop for replies, in particular, when TCP is the main transport for workloads.
  set {
    name  = "loadBalancer.mode"
    value = "hybrid"
  }

  # The kube-proxy replacement implements the K8s service Topology Aware Hints. This allows Cilium nodes to prefer service endpoints 
  # residing in the same zone. To enable the feature, set loadBalancer.serviceTopology=true.
  set {
    name  = "loadBalancer.serviceTopology"
    value = true
  }

  # This guide explains how to configure Cilium’s bandwidth manager to optimize TCP and UDP workloads and efficiently rate limit 
  # individual Pods if needed through the help of EDT (Earliest Departure Time) and eBPF. Cilium’s bandwidth manager is also prerequisite 
  # for enabling BBR congestion control for Pods as outlined below.
  set {
    name  = "bandwidthManager.enabled"
    value = true
  }

  # set {
  #   name  = "bandwidthManager.bbr"
  #   value = true
  # }

  # Hubble is the observability layer of Cilium and can be used to obtain cluster-wide visibility into the network and security layer of your 
  # Kubernetes cluster. For more information about Hubble and its components, see the Observability section.
  set {
    name  = "hubble.relay.enabled"
    value = true
  }
  set {
    name  = "hubble.ui.enabled"
    value = true
  }

  # Cilium and Hubble can both be configured to serve Prometheus metrics. Prometheus is a pluggable metrics collection and storage system and 
  # can act as a data source for Grafana, a metrics visualization frontend. Unlike some metrics collectors like statsd, Prometheus requires 
  # the collectors to pull metrics from each source.
  set {
    name  = "prometheus.enabled"
    value = true
  }
  set {
    name  = "operator.prometheus.enabled"
    value = true
  }
  set {
    name  = "hubble.metrics.enabled"
    value = "{dns,drop,tcp,flow,icmp,http}"
  }
}

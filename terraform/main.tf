terraform {
  required_providers {
    helm = { source = "hashicorp/helm", version = "~> 2.12" }
  }
}

# Node Feature Discovery (prerequisite for GPU Operator)
resource "helm_release" "node_feature_discovery" {
  name             = "node-feature-discovery"
  repository       = "https://kubernetes-sigs.github.io/node-feature-discovery/charts"
  chart            = "node-feature-discovery"
  version          = "0.15.4"
  namespace        = "node-feature-discovery"
  create_namespace = true

  set {
    name  = "worker.config.sources.pci.deviceClassWhitelist"
    value = "{0200,03,12}"
  }
}

# NVIDIA GPU Operator
resource "helm_release" "gpu_operator" {
  name             = "gpu-operator"
  repository       = "https://helm.ngc.nvidia.com/nvidia"
  chart            = "gpu-operator"
  version          = "v24.3.0"
  namespace        = "gpu-operator"
  create_namespace = true

  set {
    name  = "driver.enabled"
    value = "true"
  }
  set {
    name  = "toolkit.enabled"
    value = "true"
  }
  set {
    name  = "devicePlugin.enabled"
    value = "true"
  }
  set {
    name  = "dcgmExporter.enabled"
    value = "true"
  }
  set {
    name  = "dcgmExporter.serviceMonitor.enabled"
    value = "true"
  }
  # Reference the time-slicing ConfigMap
  set {
    name  = "devicePlugin.config.name"
    value = "time-slicing-config"
  }
  set {
    name  = "devicePlugin.config.default"
    value = "any"
  }

  depends_on = [helm_release.node_feature_discovery]
}

provider "proxmox" {
  endpoint = var.proxmox_endpoint
  insecure = var.proxmox_insecure

  # Preferred: set PROXMOX_VE_API_TOKEN in your environment.
  # This attribute exists in the provider docs; including it here for convenience.
  api_token = var.proxmox_api_token
}

# These providers are configured *after* Talos bootstraps the cluster,
# using kubeconfig material emitted by the Talos provider.
provider "kubernetes" {
  config_path = local.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = local.kubeconfig_path
  }
}

provider "proxmox" {
  endpoint = var.proxmox_endpoint
  insecure = var.proxmox_insecure

  # Preferred: set PROXMOX_VE_API_TOKEN in your environment.
  # This attribute exists in the provider docs; including it here for convenience.
  api_token = var.proxmox_api_token
}

# Configure Kubernetes/Helm providers using Talos-emitted client configuration.
#
# IMPORTANT:
# - Do NOT use config_path here: the kubeconfig file does not exist at plan time, which breaks `terraform plan`.
# - The Talos provider surfaces both kubeconfig_raw (for writing to disk) and a structured client configuration
#   we can feed directly into the Kubernetes/Helm providers.

locals {
  k8s_host = try(talos_cluster_kubeconfig.this.kubernetes_client_configuration.host, null)

  k8s_ca_cert     = try(talos_cluster_kubeconfig.this.kubernetes_client_configuration.ca_certificate, null)
  k8s_client_cert = try(talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_certificate, null)
  k8s_client_key  = try(talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_key, null)

  k8s_ca_cert_pem = local.k8s_ca_cert != null && can(regex("BEGIN CERTIFICATE", local.k8s_ca_cert)) ? local.k8s_ca_cert : (
    local.k8s_ca_cert != null ? base64decode(local.k8s_ca_cert) : null
  )

  k8s_client_cert_pem = local.k8s_client_cert != null && can(regex("BEGIN CERTIFICATE", local.k8s_client_cert)) ? local.k8s_client_cert : (
    local.k8s_client_cert != null ? base64decode(local.k8s_client_cert) : null
  )

  k8s_client_key_pem = local.k8s_client_key != null && can(regex("BEGIN", local.k8s_client_key)) ? local.k8s_client_key : (
    local.k8s_client_key != null ? base64decode(local.k8s_client_key) : null
  )
}

provider "kubernetes" {
  host                   = local.k8s_host
  cluster_ca_certificate = local.k8s_ca_cert_pem
  client_certificate     = local.k8s_client_cert_pem
  client_key             = local.k8s_client_key_pem
}

provider "helm" {
  kubernetes {
    host                   = local.k8s_host
    cluster_ca_certificate = local.k8s_ca_cert_pem
    client_certificate     = local.k8s_client_cert_pem
    client_key             = local.k8s_client_key_pem
  }
}

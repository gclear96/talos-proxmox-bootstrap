terraform {
  required_version = ">= 1.5.0"

  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      # Pinned to a narrow range to reduce churn in a Proxmox-lifecycle project.
      version = "~> 0.80.0"
    }
    talos = {
      source = "siderolabs/talos"
      # Pinned to the Talos provider minor series in use (also locked in terraform.lock.hcl).
      version = "~> 0.9.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

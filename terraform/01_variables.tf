variable "proxmox_endpoint" { type = string }
variable "proxmox_api_token" { type = string, sensitive = true, default = null }
variable "proxmox_insecure" { type = bool, default = true }

variable "cluster_name" { type = string }
variable "cluster_endpoint" { type = string }

variable "nodes" {
  description = "Map of node name -> { node_name, vm_id, ip, install_disk }"
  type = map(object({
    node_name     = string
    vm_id         = number
    ip            = string
    install_disk  = string
  }))
}

variable "vm_cores" { type = number, default = 2 }
variable "vm_memory_mb" { type = number, default = 4096 }
variable "vm_disk_gb" { type = number, default = 40 }
variable "vm_bridge" { type = string, default = "vmbr0" }
variable "vm_vlan_id" { type = number, default = null }

variable "talos_iso_url" { type = string, default = null }
variable "iso_datastore_id" { type = string, default = "local" }
variable "talos_iso_file_id" {
  description = "Proxmox file_id for an already-present ISO, e.g. local:iso/talos.iso"
  type = string
  default = null
}

variable "platform_repo_url" { type = string }
variable "platform_repo_revision" { type = string, default = "main" }
variable "platform_repo_path" { type = string, default = "clusters/homelab/bootstrap" }
variable "argocd_chart_version" { type = string, default = null }

variable "proxmox_endpoint" {
  type = string
}

variable "proxmox_api_token" {
  type      = string
  sensitive = true
  default   = null
}

variable "proxmox_insecure" {
  type    = bool
  default = true
}

variable "cluster_name" {
  type = string
}

variable "cluster_endpoint" {
  type = string
}

variable "cluster_vip_ip" {
  description = "Optional VIP address to use for the Kubernetes API (Talos will manage kube-vip)."
  type        = string
  default     = null
}

variable "cluster_vip_interface" {
  description = "Interface name to bind the VIP to (usually eth0 for a single virtio NIC)."
  type        = string
  default     = "eth0"
}

variable "nodes" {
  description = "Map of node name -> { node_name, vm_id, ip, install_disk }"
  type = map(object({
    node_name    = string
    vm_id        = number
    ip           = string
    install_disk = string
  }))
}

variable "vm_cores" {
  type    = number
  default = 2
}

variable "vm_memory_mb" {
  type    = number
  default = 4096
}

variable "vm_disk_gb" {
  type    = number
  default = 40
}

variable "vm_datastore_id" {
  description = "Proxmox datastore for the Talos install disk (e.g. local-lvm, vm-storage)."
  type        = string
  default     = "local-lvm"
}

variable "vm_efi_datastore_id" {
  description = "Proxmox datastore for the EFI disk (defaults to vm_datastore_id)."
  type        = string
  default     = null
}

variable "vm_bridge" {
  type    = string
  default = "vmbr0"
}

variable "vm_vlan_id" {
  type    = number
  default = null
}

variable "talos_iso_url" {
  description = "URL to a Talos ISO to download into Proxmox storage."
  type        = string
  default     = null

  validation {
    condition     = var.talos_iso_url != null || var.talos_iso_file_id != null
    error_message = "Set either talos_iso_url (to download) or talos_iso_file_id (existing Proxmox ISO)."
  }
}
variable "talos_iso_file_name" {
  description = "Filename to save the downloaded ISO as (when using talos_iso_url)."
  type        = string
  default     = "talos.iso"
}

variable "iso_datastore_id" {
  type    = string
  default = "local"
}

variable "talos_iso_file_id" {
  description = "Proxmox file_id for an already-present ISO, e.g. local:iso/talos.iso"
  type        = string
  default     = null
}

variable "talos_installer_image" {
  description = "Talos installer image to install onto disk (e.g. ghcr.io/siderolabs/installer:v1.8.0)."
  type        = string
}

variable "allow_scheduling_on_control_planes" {
  description = "Enable scheduling workloads on control-plane nodes (combo nodes)."
  type        = bool
  default     = true
}

variable "platform_repo_url" {
  type = string
}

variable "platform_repo_revision" {
  type    = string
  default = "main"
}

variable "platform_repo_path" {
  type    = string
  default = "clusters/homelab/bootstrap"
}

variable "argocd_chart_version" {
  type    = string
  default = null
}

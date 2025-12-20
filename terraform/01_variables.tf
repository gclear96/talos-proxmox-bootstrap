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
  description = "Map of node name -> { node_name, vm_id, ip, install_disk, mac_address? }"
  type = map(object({
    node_name    = string
    vm_id        = number
    ip           = string
    install_disk = string
    mac_address  = optional(string)
  }))
}

variable "node_network_mode" {
  description = "How Talos should configure node networking for the primary interface: dhcp or static."
  type        = string
  default     = "dhcp"

  validation {
    condition     = contains(["dhcp", "static"], var.node_network_mode)
    error_message = "node_network_mode must be one of: dhcp, static."
  }
}

variable "node_network_prefix" {
  description = "CIDR prefix length for node IPs when node_network_mode=static (e.g. 24)."
  type        = number
  default     = 24

  validation {
    condition     = var.node_network_prefix >= 1 && var.node_network_prefix <= 32
    error_message = "node_network_prefix must be between 1 and 32."
  }
}

variable "node_network_gateway" {
  description = "Default gateway for node IPs when node_network_mode=static (e.g. 192.168.50.1)."
  type        = string
  default     = null
}

variable "node_network_nameservers" {
  description = "DNS servers for nodes when node_network_mode=static (e.g. [\"192.168.50.1\"])."
  type        = list(string)
  default     = []
}

variable "node_network_mtu" {
  description = "Optional MTU to set on the primary interface (leave null to use default)."
  type        = number
  default     = null
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

variable "platform_repo_username" {
  description = "Optional repo auth for Argo CD (e.g. Forgejo username for HTTPS auth)."
  type        = string
  sensitive   = true
  default     = null
}

variable "platform_repo_password" {
  description = "Optional repo auth for Argo CD (e.g. Forgejo token/password for HTTPS auth)."
  type        = string
  sensitive   = true
  default     = null
}

variable "platform_repo_revision" {
  type    = string
  default = "main"
}

variable "platform_repo_path" {
  type    = string
  default = "clusters/homelab/bootstrap"
}

variable "kube_apiserver_wait_timeout_seconds" {
  description = "How long to wait for the Kubernetes API server to become ready before installing Argo CD."
  type        = number
  default     = 300
}

variable "kube_apiserver_wait_interval_seconds" {
  description = "Polling interval in seconds for Kubernetes API readiness."
  type        = number
  default     = 5
}

variable "argocd_chart_version" {
  type    = string
  default = null
}

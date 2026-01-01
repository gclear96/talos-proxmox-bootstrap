# Cluster config for CI (non-secret).
#
# Secrets MUST be provided via env vars / Forgejo secrets:
# - TF_VAR_proxmox_api_token (Forgejo secret: PROXMOX_VE_API_TOKEN)
# - (optional) TF_VAR_platform_repo_username / TF_VAR_platform_repo_password
#
# State backend credentials are separate (Garage S3) and are also provided via env vars.

# Proxmox
proxmox_endpoint = "https://pve1.magomago.moe/"
proxmox_insecure = true

# Cluster basics
cluster_name          = "talos-admin-1"
cluster_endpoint      = "https://192.168.50.250:6443"
cluster_vip_ip        = "192.168.50.250"
cluster_vip_interface = "ens18"

# 3 nodes (controlplane + worker)
nodes = {
  talos-1 = { node_name = "pve1", vm_id = 201, ip = "192.168.50.201", install_disk = "/dev/sda", mac_address = "BC:24:11:7C:83:F2" }
  talos-2 = { node_name = "pve2", vm_id = 202, ip = "192.168.50.202", install_disk = "/dev/sda", mac_address = "BC:24:11:B2:7D:D7" }
  talos-3 = { node_name = "pve3", vm_id = 203, ip = "192.168.50.203", install_disk = "/dev/sda", mac_address = "BC:24:11:68:50:DA" }
}

# Node network configuration
node_network_mode        = "dhcp"
node_network_prefix      = 24
node_network_gateway     = null
node_network_nameservers = []
node_network_mtu         = null

# VM sizing
vm_cores        = 4
vm_memory_mb    = 16384
vm_disk_gb      = 110
vm_datastore_id = "local"
vm_bridge       = "vmbr0"

# Talos ISO
talos_iso_url       = "https://factory.talos.dev/image/613e1592b2da41ae5e265e8789429f22e121aab91cb4deb6bc3c0b6262961245/v1.11.6/metal-amd64.iso"
talos_iso_file_name = "talos-metal-amd64.iso"
iso_datastore_id    = "local"

# Talos install image
talos_installer_image              = "factory.talos.dev/metal-installer/613e1592b2da41ae5e265e8789429f22e121aab91cb4deb6bc3c0b6262961245:v1.11.6"
allow_scheduling_on_control_planes = true

# Argo CD + platform repo
platform_repo_url      = "https://forgejo.k8s.magomago.moe/forgejo-admin/talos-proxmox-platform.git"
platform_repo_revision = "main"
platform_repo_path     = "clusters/homelab/bootstrap"
argocd_chart_version   = "9.1.9"

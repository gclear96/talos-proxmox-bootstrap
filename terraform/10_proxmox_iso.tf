# Option A: download Talos ISO into Proxmox storage (IaC-friendly).
#
# IMPORTANT:
# - If iso_datastore_id is not shared across Proxmox nodes, we download the ISO once per unique node_name.
# - If you have shared storage, you can still set talos_iso_file_id to a single shared file ID.

locals {
  proxmox_node_names = toset([for n in var.nodes : n.node_name])
}

resource "proxmox_virtual_environment_download_file" "talos_iso" {
  for_each = var.talos_iso_url != null ? local.proxmox_node_names : toset([])

  node_name    = each.value
  datastore_id = var.iso_datastore_id
  content_type = "iso"

  url       = var.talos_iso_url
  file_name = var.talos_iso_file_name
}

locals {
  talos_iso_file_id_by_node = {
    for node_name in local.proxmox_node_names :
    node_name => try(proxmox_virtual_environment_download_file.talos_iso[node_name].id, null)
  }
}

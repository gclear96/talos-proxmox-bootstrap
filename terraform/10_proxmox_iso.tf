# Option A: download Talos ISO into Proxmox storage (IaC-friendly)
# Note: if you have shared storage across nodes, download once. If not, you'll need one per node.
resource "proxmox_virtual_environment_download_file" "talos_iso" {
  count = var.talos_iso_url != null ? 1 : 0

  node_name    = values(var.nodes)[0].node_name
  datastore_id = var.iso_datastore_id
  content_type = "iso"

  url       = var.talos_iso_url
  file_name = "talos.iso"
}

locals {
  talos_iso_file_id_effective = (
    var.talos_iso_file_id != null
    ? var.talos_iso_file_id
    : (try(proxmox_virtual_environment_download_file.talos_iso[0].id, null))
  )
}

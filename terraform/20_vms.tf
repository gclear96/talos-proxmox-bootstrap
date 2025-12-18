# Creates 3 VMs, one per node in `var.nodes`.
#
# IMPORTANT:
# - This is a scaffold; you will likely adjust BIOS/UEFI, disk interface, and CD-ROM ISO attachment
#   to match your Proxmox + provider version.
# - Talos will be installed by applying a machine config that includes machine.install settings.

resource "proxmox_virtual_environment_vm" "talos" {
  for_each = var.nodes

  node_name   = each.value.node_name
  vm_id       = each.value.vm_id
  name        = each.key
  description = "Talos node managed by Terraform"
  tags        = ["terraform", "talos", "k8s"]

  cpu {
    cores = var.vm_cores
  }

  memory {
    dedicated = var.vm_memory_mb
  }

  # Primary disk (Talos install target)
  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = var.vm_disk_gb
    file_format  = "raw"
    ssd          = true
    discard      = "on"
  }

  # Network
  network_device {
    bridge  = var.vm_bridge
    vlan_id = var.vm_vlan_id
  }

  # TODO: Attach the Talos ISO as a CD-ROM device, using local.talos_iso_file_id_effective.
  # Depending on provider version, this may be a `cdrom { ... }` block or a disk with `interface = "ide2"`.

  lifecycle {
    ignore_changes = []
  }
}

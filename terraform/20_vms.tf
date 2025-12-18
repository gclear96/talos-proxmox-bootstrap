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

  # Talos-on-Proxmox recommended settings:
  # - UEFI/OVMF + q35 machine type (modern firmware + hardware model)
  # - CPU type host (avoid odd emulated CPU features)
  bios    = "ovmf"
  machine = "q35"

  cpu {
    cores = var.vm_cores
    type  = "host"
  }

  memory {
    dedicated = var.vm_memory_mb
    # Explicitly disable ballooning/hotplug (Talos guidance).
    floating = 0
  }

  # Ensure the controller is VirtIO SCSI (NOT virtio-scsi-single).
  scsi_hardware = "virtio-scsi-pci"

  # Required for OVMF boot.
  efi_disk {
    datastore_id = coalesce(var.vm_efi_datastore_id, var.vm_datastore_id)
    file_format  = "raw"
  }

  # Primary disk (Talos install target)
  disk {
    datastore_id = var.vm_datastore_id
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
    model   = "virtio"
  }

  # Attach the Talos ISO as a CD-ROM for first boot (Talos maintenance mode),
  # then Talos installs itself onto scsi0 via machine.install.* in the applied config.
  cdrom {
    enabled = true
    file_id = (
      var.talos_iso_file_id != null
      ? var.talos_iso_file_id
      : local.talos_iso_file_id_by_node[each.value.node_name]
    )
  }

  # Boot from ISO first (ide2), then boot the installed OS disk (scsi0).
  boot_order = ["ide2", "scsi0", "net0"]

  lifecycle {
    ignore_changes = []
  }
}

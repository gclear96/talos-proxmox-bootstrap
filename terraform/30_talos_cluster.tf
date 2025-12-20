locals {
  out_dir          = "${path.module}/../out"
  kubeconfig_path  = "${local.out_dir}/${var.cluster_name}.kubeconfig"
  talosconfig_path = "${local.out_dir}/${var.cluster_name}.talosconfig"
  bootstrap_node   = sort(keys(var.nodes))[0]
  bootstrap_ip     = var.nodes[local.bootstrap_node].ip
}

# Generate secrets (PKI etc) for the cluster
resource "talos_machine_secrets" "this" {}

# Generate the (base) machine configuration for control plane nodes.
data "talos_machine_configuration" "controlplane" {
  cluster_name     = var.cluster_name
  cluster_endpoint = var.cluster_endpoint
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
}

# Apply machine configuration to each node (with a per-node install disk + hostname patch)
resource "talos_machine_configuration_apply" "cp" {
  for_each = var.nodes

  depends_on = [proxmox_virtual_environment_vm.talos]

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  node                        = each.value.ip
  endpoint                    = each.value.ip

  config_patches = compact([
    templatefile("${path.module}/patches/node.yaml", {
      hostname                           = each.key
      install_disk                       = each.value.install_disk
      installer_image                    = var.talos_installer_image
      allow_scheduling_on_control_planes = var.allow_scheduling_on_control_planes
    }),
    (var.node_network_mode == "static" || var.cluster_vip_ip != null) ? templatefile("${path.module}/patches/network.yaml", {
      interface   = var.cluster_vip_interface
      dhcp        = var.node_network_mode == "dhcp"
      ip          = each.value.ip
      prefix      = var.node_network_prefix
      gateway     = var.node_network_gateway
      nameservers = var.node_network_nameservers
      vip_ip      = var.cluster_vip_ip
      mtu         = var.node_network_mtu
    }) : null,
  ])

  lifecycle {
    precondition {
      condition     = var.node_network_mode != "static" || (var.node_network_gateway != null && length(var.node_network_nameservers) > 0)
      error_message = "When node_network_mode=static you must set node_network_gateway and at least one node_network_nameservers entry."
    }
  }
}

# Bootstrap etcd on one node
resource "talos_machine_bootstrap" "bootstrap" {
  depends_on = [talos_machine_configuration_apply.cp]

  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.bootstrap_ip
}

# Fetch kubeconfig + talosconfig for local use
resource "talos_cluster_kubeconfig" "this" {
  depends_on = [talos_machine_bootstrap.bootstrap]

  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.bootstrap_ip
}

data "talos_client_configuration" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  cluster_name         = var.cluster_name
  endpoints            = [for n in var.nodes : n.ip]
}

resource "local_sensitive_file" "kubeconfig" {
  filename        = local.kubeconfig_path
  content         = talos_cluster_kubeconfig.this.kubeconfig_raw
  file_permission = "0600"
}

resource "local_sensitive_file" "talosconfig" {
  filename        = local.talosconfig_path
  content         = data.talos_client_configuration.this.talos_config
  file_permission = "0600"
}

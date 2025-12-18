locals {
  out_dir          = "${path.module}/../out"
  kubeconfig_path  = "${local.out_dir}/${var.cluster_name}.kubeconfig"
  talosconfig_path = "${local.out_dir}/${var.cluster_name}.talosconfig"
}

resource "local_file" "out_dir_marker" {
  filename = "${local.out_dir}/.keep"
  content  = "generated"
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

  client_configuration         = talos_machine_secrets.this.client_configuration
  machine_configuration_input  = data.talos_machine_configuration.controlplane.machine_configuration
  node                         = each.value.ip
  endpoint                     = each.value.ip

  config_patches = [
    templatefile("${path.module}/patches/node.yaml", {
      hostname     = each.key
      install_disk = each.value.install_disk
    })
  ]
}

# Bootstrap etcd on one node
resource "talos_machine_bootstrap" "bootstrap" {
  depends_on = [talos_machine_configuration_apply.cp]

  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = values(var.nodes)[0].ip
}

# Fetch kubeconfig + talosconfig for local use
data "talos_cluster_kubeconfig" "this" {
  depends_on = [talos_machine_bootstrap.bootstrap]

  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = values(var.nodes)[0].ip
}

data "talos_client_configuration" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  cluster_name         = var.cluster_name
  endpoints            = [for n in var.nodes : n.ip]
}

resource "local_file" "kubeconfig" {
  filename = local.kubeconfig_path
  content  = data.talos_cluster_kubeconfig.this.kubeconfig_raw
}

resource "local_file" "talosconfig" {
  filename = local.talosconfig_path
  content  = data.talos_client_configuration.this.talos_config
}

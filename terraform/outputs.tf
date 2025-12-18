output "kubeconfig_path" {
  value       = local.kubeconfig_path
  description = "Path to the generated kubeconfig"
}

output "talosconfig_path" {
  value       = local.talosconfig_path
  description = "Path to the generated talosconfig"
}

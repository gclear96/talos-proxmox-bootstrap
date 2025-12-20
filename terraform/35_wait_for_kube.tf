resource "terraform_data" "wait_for_kube" {
  depends_on = [
    talos_machine_bootstrap.bootstrap,
    local_sensitive_file.kubeconfig,
  ]

  triggers_replace = {
    kubeconfig_sha = fileexists(local.kubeconfig_path) ? filesha256(local.kubeconfig_path) : "missing"
  }

  provisioner "local-exec" {
    command = "${path.module}/../scripts/wait-for-kube.sh"
    environment = {
      KUBECONFIG       = local.kubeconfig_path
      TIMEOUT_SECONDS  = var.kube_apiserver_wait_timeout_seconds
      INTERVAL_SECONDS = var.kube_apiserver_wait_interval_seconds
    }
  }
}

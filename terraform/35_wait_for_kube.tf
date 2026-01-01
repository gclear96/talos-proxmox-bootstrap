resource "terraform_data" "wait_for_kube" {
  depends_on = [
    talos_machine_bootstrap.bootstrap,
    local_sensitive_file.kubeconfig,
  ]

  triggers_replace = {
    # Avoid reading from the local filesystem (CI runners are ephemeral and won't have ../out/*),
    # but still re-run the readiness wait if the kubeconfig content changes.
    kubeconfig_sha = sha256(talos_cluster_kubeconfig.this.kubeconfig_raw)
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

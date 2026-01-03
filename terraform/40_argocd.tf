# Install Argo CD via Helm chart, and inject the "root" application (and optional repo secret)
# via a second Helm release after CRDs are installed.
#
# Why:
# - `kubernetes_manifest` requires a working Kubernetes REST client during `terraform plan`.
# - Helm (provider) validates objects against the live API before CRDs from the same release exist.
#   So we install Argo CD (and its CRDs) first, then apply the root Application in a separate release.

locals {
  argocd_namespace = "argocd"
}

resource "helm_release" "argocd" {
  name       = "argo-cd"
  namespace  = local.argocd_namespace
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"

  create_namespace = true

  # Optional pin
  version = var.argocd_chart_version

  wait    = true
  atomic  = true
  timeout = 900

  values = [yamlencode({
    applicationSet = {
      enabled = true
    }
    configs = {
      cm = {
        # Allow Argo CD to pull Helm charts from OCI registries (needed for Forgejo chart sources).
        "helm.oci.enabled" = "true"
        "url"              = "https://argocd.k8s.magomago.moe"
        "oidc.config"      = <<-EOT
name: Authentik
issuer: https://authentik.k8s.magomago.moe/application/o/argocd/
clientID: argocd
clientSecret: $oidc.authentik.clientSecret
requestedScopes:
  - openid
  - profile
  - email
EOT
      }
    }
  })]

  depends_on = [terraform_data.wait_for_kube]
}

resource "helm_release" "platform_root" {
  name      = "platform-root"
  namespace = local.argocd_namespace

  chart = "${path.module}/charts/platform-root"

  create_namespace = true

  wait    = false
  atomic  = false
  timeout = 300

  values = [yamlencode({
    platform = {
      repoURL  = var.platform_repo_url
      revision = var.platform_repo_revision
      path     = var.platform_repo_path
      repoAuth = {
        enabled  = var.platform_repo_username != null && var.platform_repo_password != null
        username = var.platform_repo_username
        password = var.platform_repo_password
      }
    }
  })]

  depends_on = [helm_release.argocd]
}

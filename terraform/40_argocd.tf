# Install Argo CD via Helm chart, and inject the "root" application (and optional repo secret)
# via chart `extraObjects`.
#
# Why: `kubernetes_manifest` requires a working Kubernetes REST client during `terraform plan`,
# which isn't available until Talos bootstraps and emits client configuration.

locals {
  argocd_namespace = "argocd"

  argocd_extra_objects = concat([
    {
      apiVersion = "argoproj.io/v1alpha1"
      kind       = "Application"
      metadata = {
        name      = "platform-root"
        namespace = local.argocd_namespace
      }
      spec = {
        project = "default"
        source = {
          repoURL        = var.platform_repo_url
          targetRevision = var.platform_repo_revision
          path           = var.platform_repo_path
        }
        destination = {
          server    = "https://kubernetes.default.svc"
          namespace = local.argocd_namespace
        }
        syncPolicy = {
          automated = {
            prune    = true
            selfHeal = true
          }
          syncOptions = [
            "CreateNamespace=true",
          ]
        }
      }
    },
    ], var.platform_repo_username != null && var.platform_repo_password != null ? [
    {
      apiVersion = "v1"
      kind       = "Secret"
      metadata = {
        name      = "platform-repo"
        namespace = local.argocd_namespace
        labels = {
          "argocd.argoproj.io/secret-type" = "repository"
        }
      }
      type = "Opaque"
      stringData = {
        url      = var.platform_repo_url
        username = var.platform_repo_username
        password = var.platform_repo_password
      }
    },
  ] : [])
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
      }
    }
    extraObjects = local.argocd_extra_objects
  })]

  depends_on = [talos_cluster_kubeconfig.this]
}

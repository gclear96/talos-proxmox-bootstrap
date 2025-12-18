# Install Argo CD via Helm chart, then apply the "root" application that points to the platform repo.

resource "kubernetes_namespace" "argocd" {
  depends_on = [local_sensitive_file.kubeconfig]
  metadata { name = "argocd" }
}

resource "kubernetes_manifest" "platform_repo" {
  count = var.platform_repo_username != null && var.platform_repo_password != null ? 1 : 0

  depends_on = [kubernetes_namespace.argocd]

  manifest = {
    apiVersion = "v1"
    kind       = "Secret"
    metadata = {
      name      = "platform-repo"
      namespace = kubernetes_namespace.argocd.metadata[0].name
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
  }
}

resource "helm_release" "argocd" {
  name       = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"

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
  })]

  depends_on = [local_sensitive_file.kubeconfig, kubernetes_namespace.argocd]
}

# Root app: points to the platform repo, which contains ApplicationSets / AppProjects etc.
resource "kubernetes_manifest" "platform_root_app" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "platform-root"
      namespace = "argocd"
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
        namespace = "argocd"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = [
          "CreateNamespace=true"
        ]
      }
    }
  }

  depends_on = [helm_release.argocd, kubernetes_manifest.platform_repo]
}

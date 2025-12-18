# Install Argo CD via Helm chart, then apply the "root" application that points to the platform repo.

resource "kubernetes_namespace" "argocd" {
  metadata { name = "argocd" }
}

resource "helm_release" "argocd" {
  name       = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"

  # Optional pin
  version = var.argocd_chart_version
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

  depends_on = [helm_release.argocd]
}

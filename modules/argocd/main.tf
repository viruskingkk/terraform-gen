# ============================================================
# terraform/modules/argocd/main.tf
# ============================================================

# 安裝 ArgoCD
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "6.7.0"
  namespace  = "argocd"

  set {
    name  = "server.ingress.enabled"
    value = "true"
  }
  set {
    name  = "server.ingress.ingressClassName"
    value = "nginx"
  }
  set {
    name  = "server.ingress.hosts[0]"
    value = var.argocd_domain
  }
  set {
    name  = "server.ingress.tls[0].secretName"
    value = "argocd-tls"
  }
  set {
    name  = "server.ingress.tls[0].hosts[0]"
    value = var.argocd_domain
  }
  set {
    name  = "configs.params.server\\.insecure"
    value = "true"
  }

  timeout = 600
  wait    = true
}

# ArgoCD AppProject + Applications（透過 kubectl provider）
resource "kubectl_manifest" "argocd_project" {
  yaml_body = templatefile("${path.module}/appproject.yaml.tpl", {
    gitlab_repo_url = var.gitlab_repo_url
  })

  depends_on = [helm_release.argocd]
}

resource "kubectl_manifest" "argocd_app_dev" {
  yaml_body = templatefile("${path.module}/application.yaml.tpl", {
    name            = "myapp-dev"
    environment     = "dev"
    namespace       = "dev"
    gitlab_repo_url = var.gitlab_repo_url
    auto_sync       = true
  })

  depends_on = [kubectl_manifest.argocd_project]
}

resource "kubectl_manifest" "argocd_app_staging" {
  yaml_body = templatefile("${path.module}/application.yaml.tpl", {
    name            = "myapp-staging"
    environment     = "staging"
    namespace       = "staging"
    gitlab_repo_url = var.gitlab_repo_url
    auto_sync       = true
  })

  depends_on = [kubectl_manifest.argocd_project]
}

resource "kubectl_manifest" "argocd_app_prod" {
  yaml_body = templatefile("${path.module}/application.yaml.tpl", {
    name            = "myapp-prod"
    environment     = "prod"
    namespace       = "prod"
    gitlab_repo_url = var.gitlab_repo_url
    auto_sync       = false   # prod 手動 sync
  })

  depends_on = [kubectl_manifest.argocd_project]
}

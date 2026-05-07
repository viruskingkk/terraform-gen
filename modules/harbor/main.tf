# ============================================================
# terraform/modules/harbor/main.tf
# ============================================================

resource "helm_release" "harbor" {
  name       = "harbor"
  repository = "https://helm.goharbor.io"
  chart      = "harbor"
  version    = "1.14.0"
  namespace  = "harbor"

  values = [
    templatefile("${path.module}/values.yaml.tpl", {
      harbor_domain   = var.harbor_domain
      harbor_password = var.harbor_password
    })
  ]

  timeout = 600
  wait    = true
}

# ── values template ──────────────────────────────────────────
# 寫入 locals 等效的 values（避免額外檔案）
locals {
  harbor_values = yamlencode({
    expose = {
      type = "ingress"
      tls = {
        enabled    = true
        certSource = "secret"
        secret     = { secretName = "harbor-tls" }
      }
      ingress = {
        hosts = { core = var.harbor_domain }
        className = "nginx"
        annotations = {
          "nginx.ingress.kubernetes.io/ssl-redirect"  = "true"
          "nginx.ingress.kubernetes.io/proxy-body-size" = "0"
        }
      }
    }
    externalURL          = "https://${var.harbor_domain}"
    harborAdminPassword  = var.harbor_password
    persistence = {
      enabled = true
      persistentVolumeClaim = {
        registry = { storageClass = "gp3", size = "50Gi" }
        database = { storageClass = "gp3", size = "5Gi"  }
        redis    = { storageClass = "gp3", size = "2Gi"  }
      }
    }
    trivy   = { enabled = true }
    metrics = { enabled = true }
  })
}

resource "helm_release" "harbor_v2" {
  name       = "harbor"
  repository = "https://helm.goharbor.io"
  chart      = "harbor"
  version    = "1.14.0"
  namespace  = "harbor"
  values     = [local.harbor_values]
  timeout    = 600
  wait       = true

  lifecycle {
    ignore_changes = [values]
  }
}

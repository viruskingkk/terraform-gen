# ============================================================
# terraform/modules/mysql/main.tf
# ============================================================

resource "kubernetes_namespace" "mysql" {
  metadata { name = "mysql" }
}

resource "helm_release" "mysql" {
  name       = "mysql"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "mysql"
  version    = "10.1.0"
  namespace  = kubernetes_namespace.mysql.metadata[0].name

  values = [yamlencode({
    auth = {
      rootPassword = var.root_password
      database     = "appdb"
    }
    primary = {
      persistence = {
        enabled          = true
        storageClass     = "gp3"
        size             = var.storage_size
      }
      resources = {
        requests = { cpu = "250m", memory = "512Mi" }
        limits   = { cpu = "1000m", memory = "1Gi" }
      }
    }
    secondary = {
      replicaCount = var.mode == "standalone" ? 0 : (var.mode == "replication" ? 1 : 2)
      persistence = {
        enabled      = true
        storageClass = "gp3"
        size         = var.storage_size
      }
    }
    metrics = { enabled = true }
  })]

  timeout = 600
  wait    = true
  depends_on = [kubernetes_namespace.mysql]
}

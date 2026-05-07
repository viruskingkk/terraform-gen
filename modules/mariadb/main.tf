# ============================================================
# terraform/modules/mariadb/main.tf
# ============================================================

resource "kubernetes_namespace" "mariadb" {
  metadata { name = "mariadb" }
}

resource "helm_release" "mariadb" {
  name       = "mariadb"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "mariadb"
  version    = "16.5.0"
  namespace  = kubernetes_namespace.mariadb.metadata[0].name

  values = [yamlencode({
    auth = {
      rootPassword = var.root_password
      database     = "appdb"
    }
    primary = {
      persistence = {
        enabled      = true
        storageClass = "gp3"
        size         = var.storage_size
      }
      resources = {
        requests = { cpu = "250m", memory = "512Mi" }
        limits   = { cpu = "1000m", memory = "1Gi" }
      }
    }
    secondary = {
      replicaCount = var.mode == "standalone" ? 0 : var.replica_count - 1
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
  depends_on = [kubernetes_namespace.mariadb]
}

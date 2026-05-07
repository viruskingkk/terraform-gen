# ============================================================
# terraform/modules/postgres/main.tf
# ============================================================

resource "kubernetes_namespace" "postgres" {
  metadata { name = "postgres" }
}

resource "helm_release" "postgres" {
  name       = "postgres"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql"
  version    = "14.3.3"
  namespace  = kubernetes_namespace.postgres.metadata[0].name

  values = [yamlencode({
    auth = {
      postgresPassword = var.root_password
      database         = "appdb"
    }
    primary = {
      persistence = {
        enabled      = true
        storageClass = "gp3"
        size         = var.storage_size
      }
      resources = {
        requests = { cpu = "250m", memory = "256Mi" }
        limits   = { cpu = "1000m", memory = "1Gi" }
      }
    }
    readReplicas = {
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
  depends_on = [kubernetes_namespace.postgres]
}

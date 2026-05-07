# ============================================================
# terraform/modules/clickhouse/main.tf
# ============================================================

resource "kubernetes_namespace" "clickhouse" {
  metadata { name = "clickhouse" }
}

resource "helm_release" "clickhouse" {
  name       = "clickhouse"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "clickhouse"
  version    = "6.2.11"
  namespace  = kubernetes_namespace.clickhouse.metadata[0].name

  values = [yamlencode({
    replicaCount = var.replica_count
    shards       = 1

    auth = {
      username = "default"
      password = "clickhouse"
    }

    persistence = {
      enabled      = true
      storageClass = "gp3"
      size         = var.storage_size
    }

    resources = {
      requests = { cpu = "500m",  memory = "1Gi" }
      limits   = { cpu = "2000m", memory = "4Gi" }
    }

    zookeeper = { enabled = var.replica_count > 1 }
    metrics   = { enabled = true }
  })]

  timeout = 600
  wait    = true
  depends_on = [kubernetes_namespace.clickhouse]
}

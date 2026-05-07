# ============================================================
# terraform/modules/cassandra/main.tf
# ============================================================

resource "kubernetes_namespace" "cassandra" {
  metadata { name = "cassandra" }
}

resource "helm_release" "cassandra" {
  name       = "cassandra"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "cassandra"
  version    = "11.3.10"
  namespace  = kubernetes_namespace.cassandra.metadata[0].name

  values = [yamlencode({
    replicaCount = var.replica_count
    dbUser = { password = "cassandra" }

    persistence = {
      enabled      = true
      storageClass = "gp3"
      size         = var.storage_size
    }

    resources = {
      requests = { cpu = "500m",  memory = "2Gi" }
      limits   = { cpu = "2000m", memory = "4Gi" }
    }

    jvm = { maxHeapSize = "1024M", newHeapSize = "256M" }
    metrics = { enabled = true }
  })]

  timeout = 600
  wait    = true
  depends_on = [kubernetes_namespace.cassandra]
}

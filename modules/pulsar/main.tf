# ============================================================
# terraform/modules/pulsar/main.tf
# ============================================================

resource "kubernetes_namespace" "pulsar" {
  metadata { name = "pulsar" }
}

resource "helm_release" "pulsar" {
  name       = "pulsar"
  repository = "https://pulsar.apache.org/charts"
  chart      = "pulsar"
  version    = "3.3.0"
  namespace  = kubernetes_namespace.pulsar.metadata[0].name

  values = [yamlencode({
    initialize = true

    broker = {
      replicaCount = var.broker_replicas
      resources = {
        requests = { cpu = "500m",  memory = "512Mi" }
        limits   = { cpu = "2000m", memory = "2Gi" }
      }
    }

    bookkeeper = {
      replicaCount = var.broker_replicas
      volumes = {
        journal   = { size = var.storage_size, storageClassName = "gp3" }
        ledgers   = { size = var.storage_size, storageClassName = "gp3" }
      }
    }

    zookeeper = {
      replicaCount = 3
      volumes = {
        data = { size = "5Gi", storageClassName = "gp3" }
      }
    }

    proxy = {
      replicaCount = 1
      service = { type = "ClusterIP" }
    }

    monitoring = { enabled = true }
  })]

  timeout = 900
  wait    = true
  depends_on = [kubernetes_namespace.pulsar]
}

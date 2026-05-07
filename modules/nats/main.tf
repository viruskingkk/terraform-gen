# ============================================================
# terraform/modules/nats/main.tf
# ============================================================

resource "kubernetes_namespace" "nats" {
  metadata { name = "nats" }
}

resource "helm_release" "nats" {
  name       = "nats"
  repository = "https://nats-io.github.io/k8s/helm/charts"
  chart      = "nats"
  version    = "1.1.12"
  namespace  = kubernetes_namespace.nats.metadata[0].name

  values = [yamlencode({
    config = {
      cluster = {
        enabled  = var.replica_count > 1
        replicas = var.replica_count
      }
      jetstream = {
        enabled   = true
        fileStore = {
          enabled = true
          dir     = "/data"
          pvc = {
            enabled          = true
            size             = "5Gi"
            storageClassName = "gp3"
          }
        }
      }
      merge = {
        max_payload = "8MB"
      }
    }

    container = {
      image = { tag = "2.10.14-alpine" }
      resources = {
        requests = { cpu = "100m", memory = "128Mi" }
        limits   = { cpu = "500m", memory = "512Mi" }
      }
    }

    promExporter = {
      enabled = true
      podMonitor = { enabled = true }
    }
  })]

  timeout = 300
  wait    = true
  depends_on = [kubernetes_namespace.nats]
}

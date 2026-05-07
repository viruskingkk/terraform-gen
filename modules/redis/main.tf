# ============================================================
# terraform/modules/redis/main.tf
# ============================================================

resource "kubernetes_namespace" "redis" {
  metadata { name = "redis" }
}

resource "helm_release" "redis" {
  name       = "redis"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "redis"
  version    = "19.5.5"
  namespace  = kubernetes_namespace.redis.metadata[0].name

  values = [yamlencode({
    auth     = { enabled = true, password = var.password }
    # standalone / sentinel / cluster 三種模式
    architecture = var.mode == "cluster" ? "replication" : (var.mode == "sentinel" ? "replication" : "standalone")

    master = {
      persistence = {
        enabled      = true
        storageClass = "gp3"
        size         = var.storage_size
      }
      resources = {
        requests = { cpu = "100m", memory = "128Mi" }
        limits   = { cpu = "500m", memory = "512Mi" }
      }
    }

    replica = {
      replicaCount = var.mode == "standalone" ? 0 : var.replica_count - 1
      persistence = {
        enabled      = true
        storageClass = "gp3"
        size         = var.storage_size
      }
    }

    sentinel = {
      enabled      = var.mode == "sentinel"
      masterSet    = "mymaster"
      quorum       = 2
    }

    metrics = { enabled = true }
  })]

  timeout = 600
  wait    = true
  depends_on = [kubernetes_namespace.redis]
}

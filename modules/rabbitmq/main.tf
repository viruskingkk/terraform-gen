# ============================================================
# terraform/modules/rabbitmq/main.tf
# ============================================================

resource "kubernetes_namespace" "rabbitmq" {
  metadata { name = "rabbitmq" }
}

resource "helm_release" "rabbitmq" {
  name       = "rabbitmq"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "rabbitmq"
  version    = "14.6.6"
  namespace  = kubernetes_namespace.rabbitmq.metadata[0].name

  values = [yamlencode({
    replicaCount = var.replica_count

    auth = {
      username = "admin"
      password = var.password
      erlangCookie = "secreterlangcookie"
    }

    clustering = { enabled = var.replica_count > 1 }

    persistence = {
      enabled      = true
      storageClass = "gp3"
      size         = var.storage_size
    }

    resources = {
      requests = { cpu = "250m", memory = "256Mi" }
      limits   = { cpu = "1000m", memory = "1Gi" }
    }

    plugins = "rabbitmq_management rabbitmq_peer_discovery_k8s rabbitmq_prometheus"

    metrics = {
      enabled = true
      serviceMonitor = { enabled = true }
    }

    ingress = {
      enabled          = false  # 管理介面不對外；若需要可改 true
      ingressClassName = "nginx"
    }
  })]

  timeout = 600
  wait    = true
  depends_on = [kubernetes_namespace.rabbitmq]
}

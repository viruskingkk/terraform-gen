# ============================================================
# terraform/modules/activemq/main.tf  (ActiveMQ Artemis)
# ============================================================

resource "kubernetes_namespace" "activemq" {
  metadata { name = "activemq" }
}

resource "helm_release" "activemq" {
  name       = "activemq"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "activemq"
  version    = "4.0.2"
  namespace  = kubernetes_namespace.activemq.metadata[0].name

  values = [yamlencode({
    replicaCount = 1

    auth = {
      enabled  = true
      username = "admin"
      password = "activemq"
    }

    persistence = {
      enabled      = true
      storageClass = "gp3"
      size         = var.storage_size
    }

    resources = {
      requests = { cpu = "250m", memory = "512Mi" }
      limits   = { cpu = "1000m", memory = "1Gi" }
    }

    metrics = { enabled = true }
  })]

  timeout = 600
  wait    = true
  depends_on = [kubernetes_namespace.activemq]
}

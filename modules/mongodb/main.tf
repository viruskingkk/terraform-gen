# ============================================================
# terraform/modules/mongodb/main.tf
# ============================================================

resource "kubernetes_namespace" "mongodb" {
  metadata { name = "mongodb" }
}

resource "helm_release" "mongodb" {
  name       = "mongodb"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "mongodb"
  version    = "15.6.18"
  namespace  = kubernetes_namespace.mongodb.metadata[0].name

  values = [yamlencode({
    auth = {
      enabled       = true
      rootPassword  = var.root_password
      replicaSetKey = "mongoReplicaSetKey"
    }
    architecture = var.mode == "replicaset" ? "replicaset" : "standalone"
    replicaCount = var.replica_count

    persistence = {
      enabled      = true
      storageClass = "gp3"
      size         = var.storage_size
    }

    resources = {
      requests = { cpu = "250m", memory = "512Mi" }
      limits   = { cpu = "1000m", memory = "2Gi" }
    }

    metrics = { enabled = true }
  })]

  timeout = 600
  wait    = true
  depends_on = [kubernetes_namespace.mongodb]
}

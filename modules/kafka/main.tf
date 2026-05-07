# ============================================================
# terraform/modules/kafka/main.tf
# ============================================================

resource "kubernetes_namespace" "kafka" {
  metadata { name = "kafka" }
}

resource "helm_release" "kafka" {
  name       = "kafka"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "kafka"
  version    = "28.3.0"
  namespace  = kubernetes_namespace.kafka.metadata[0].name

  values = [yamlencode({
    replicaCount = var.broker_count

    # KRaft 模式（無 ZooKeeper）
    kraft = {
      enabled = var.mode == "kraft"
    }

    zookeeper = {
      enabled = var.mode == "zk"
    }

    persistence = {
      enabled      = true
      storageClass = "gp3"
      size         = var.storage_size
    }

    resources = {
      requests = { cpu = "250m",  memory = "512Mi" }
      limits   = { cpu = "2000m", memory = "2Gi" }
    }

    # 允許自動建立 topic（開發用；Prod 建議設 false）
    autoCreateTopicsEnable = true
    deleteTopicEnable      = true
    numPartitions          = 3
    defaultReplicationFactor = var.broker_count >= 3 ? 3 : var.broker_count

    metrics = {
      kafka     = { enabled = true }
      jmx       = { enabled = true }
      serviceMonitor = { enabled = true }
    }
  })]

  timeout = 600
  wait    = true
  depends_on = [kubernetes_namespace.kafka]
}

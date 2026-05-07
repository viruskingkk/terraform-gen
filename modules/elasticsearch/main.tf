# ============================================================
# terraform/modules/elasticsearch/main.tf  (獨立，非 ELK Stack)
# ============================================================

resource "kubernetes_namespace" "elasticsearch" {
  metadata { name = "elasticsearch" }
}

resource "helm_release" "elasticsearch" {
  name       = "elasticsearch"
  repository = "https://helm.elastic.co"
  chart      = "elasticsearch"
  version    = "8.5.1"
  namespace  = kubernetes_namespace.elasticsearch.metadata[0].name

  values = [yamlencode({
    replicas           = var.replica_count
    minimumMasterNodes = var.replica_count == 1 ? 1 : 2

    esJavaOpts = "-Xmx1g -Xms1g"
    resources = {
      requests = { cpu = "500m", memory = "2Gi" }
      limits   = { cpu = "2000m", memory = "2Gi" }
    }

    volumeClaimTemplate = {
      storageClassName = "gp3"
      resources = { requests = { storage = var.storage_size } }
    }

    xpack_security_enabled = false
  })]

  timeout = 600
  wait    = true
  depends_on = [kubernetes_namespace.elasticsearch]
}

# ============================================================
# terraform/modules/elk/main.tf
# ============================================================

# Elasticsearch
resource "helm_release" "elasticsearch" {
  name       = "elasticsearch"
  repository = "https://helm.elastic.co"
  chart      = "elasticsearch"
  version    = "8.5.1"
  namespace  = "logging"

  set { name = "replicas";           value = "1" }
  set { name = "minimumMasterNodes"; value = "1" }
  set { name = "resources.requests.memory"; value = "2Gi" }
  set { name = "resources.limits.memory";   value = "2Gi" }
  set { name = "volumeClaimTemplate.storageClassName"; value = "gp3" }
  set { name = "volumeClaimTemplate.resources.requests.storage"; value = "50Gi" }
  set { name = "esJavaOpts"; value = "-Xmx1g -Xms1g" }
  set { name = "xpack_security_enabled"; value = "false" }

  timeout = 600
  wait    = true
}

# Kibana
resource "helm_release" "kibana" {
  name       = "kibana"
  repository = "https://helm.elastic.co"
  chart      = "kibana"
  version    = "8.5.1"
  namespace  = "logging"

  set { name = "elasticsearchHosts"; value = "http://elasticsearch-master:9200" }
  set { name = "ingress.enabled";    value = "true" }
  set { name = "ingress.ingressClassName"; value = "nginx" }
  set { name = "ingress.hosts[0].host"; value = var.kibana_domain }
  set { name = "ingress.hosts[0].paths[0].path"; value = "/" }
  set { name = "ingress.tls[0].secretName"; value = "kibana-tls" }
  set { name = "ingress.tls[0].hosts[0]"; value = var.kibana_domain }

  timeout = 300
  wait    = true

  depends_on = [helm_release.elasticsearch]
}

# Logstash
resource "helm_release" "logstash" {
  name       = "logstash"
  repository = "https://helm.elastic.co"
  chart      = "logstash"
  version    = "8.5.1"
  namespace  = "logging"

  set { name = "logstashConfig.logstash\\.yml"; value = "http.host: 0.0.0.0\npipeline.workers: 2" }
  set { name = "resources.requests.memory"; value = "1Gi" }
  set { name = "resources.limits.memory";   value = "1Gi" }

  timeout = 300
  wait    = true

  depends_on = [helm_release.elasticsearch]
}

# Fluent Bit（DaemonSet，讀取 hostPath log）
resource "helm_release" "fluent_bit" {
  name       = "fluent-bit"
  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluent-bit"
  version    = "0.46.0"
  namespace  = "logging"

  set { name = "config.outputs";
        value = "[OUTPUT]\n    Name  forward\n    Match *\n    Host  logstash\n    Port  5044" }

  set { name = "extraVolumes[0].name";           value = "varlog" }
  set { name = "extraVolumes[0].hostPath.path";  value = "/var/log" }
  set { name = "extraVolumeMounts[0].name";      value = "varlog" }
  set { name = "extraVolumeMounts[0].mountPath"; value = "/var/log" }
  set { name = "extraVolumeMounts[0].readOnly";  value = "false" }

  depends_on = [helm_release.logstash]
}

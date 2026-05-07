# ============================================================
# terraform/modules/monitoring/main.tf
# kube-prometheus-stack（Prometheus + Grafana + Alertmanager）
# ============================================================

resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "57.0.0"
  namespace  = "monitoring"

  values = [
    yamlencode({
      grafana = {
        adminPassword = "changeme-strong-password"
        ingress = {
          enabled           = true
          ingressClassName  = "nginx"
          hosts             = [var.grafana_domain]
          tls               = [{ secretName = "grafana-tls", hosts = [var.grafana_domain] }]
        }
        "grafana.ini" = {
          server = { root_url = "https://${var.grafana_domain}" }
          "auth.gitlab" = {
            enabled        = true
            allow_sign_up  = true
            client_id      = var.gitlab_client_id
            client_secret  = var.gitlab_client_secret
            scopes         = "read_api"
            auth_url       = "${var.gitlab_base_url}/oauth/authorize"
            token_url      = "${var.gitlab_base_url}/oauth/token"
            api_url        = "${var.gitlab_base_url}/api/v4"
          }
        }
        persistence = {
          enabled          = true
          storageClassName = "gp3"
          size             = "5Gi"
        }
        # 自動匯入 Dashboard
        dashboardProviders = {
          "dashboardproviders.yaml" = {
            apiVersion = 1
            providers  = [{ name = "default", orgId = 1, folder = "GitOps", type = "file",
                            options = { path = "/var/lib/grafana/dashboards/default" } }]
          }
        }
        dashboards = {
          default = {
            jvm-micrometer    = { gnetId = 4701,  revision = 1, datasource = "Prometheus" }
            kubernetes-all    = { gnetId = 15757, revision = 1, datasource = "Prometheus" }
            node-exporter     = { gnetId = 11074, revision = 9, datasource = "Prometheus" }
          }
        }
      }

      prometheus = {
        prometheusSpec = {
          retention          = "15d"
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = "gp3"
                resources        = { requests = { storage = "30Gi" } }
              }
            }
          }
        }
      }

      alertmanager = {
        alertmanagerSpec = {
          storage = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = "gp3"
                resources        = { requests = { storage = "2Gi" } }
              }
            }
          }
        }
        config = {
          global = {
            resolve_timeout = "5m"
          }
          route = {
            group_by        = ["alertname", "namespace"]
            group_wait      = "30s"
            repeat_interval = "12h"
            receiver        = "default"
            routes = [
              { match = { severity = "critical" }, receiver = "critical-receiver" }
            ]
          }
          receivers = [
            {
              name = "default"
              email_configs = [{ to = var.alertmanager_email, send_resolved = true }]
            },
            {
              name = "critical-receiver"
              slack_configs = [{
                api_url      = var.slack_webhook_url
                channel      = "#alerts-critical"
                send_resolved = true
              }]
            }
          ]
        }
      }

      # Node Exporter 已包含在 kube-prometheus-stack 內
      nodeExporter = { enabled = true }

      # kube-state-metrics 已包含
      kubeStateMetrics = { enabled = true }
    })
  ]

  timeout = 600
  wait    = true
}

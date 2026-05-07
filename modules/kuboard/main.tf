# ============================================================
# terraform/modules/kuboard/main.tf
# ============================================================

resource "kubernetes_deployment" "kuboard" {
  metadata {
    name      = "kuboard"
    namespace = "kuboard"
    labels    = { app = "kuboard" }
  }

  spec {
    replicas = 1
    selector { match_labels = { app = "kuboard" } }

    template {
      metadata { labels = { app = "kuboard" } }

      spec {
        service_account_name = kubernetes_service_account.kuboard.metadata[0].name

        container {
          name  = "kuboard"
          image = "eipwork/kuboard:v3"

          port { container_port = 80;    name = "http" }
          port { container_port = 10081; name = "agent" }

          env { name = "KUBOARD_ENDPOINT";              value = "https://${var.kuboard_domain}" }
          env { name = "KUBOARD_AGENT_SERVER_TCP_PORT"; value = "10081" }
          env { name = "KUBOARD_LOGIN_TYPE";            value = "gitlab" }
          env { name = "KUBOARD_GITLAB_BASE_URL";       value = var.gitlab_base_url }
          env { name = "KUBOARD_GITLAB_API_SERVER";     value = var.gitlab_base_url }

          env {
            name = "KUBOARD_GITLAB_APPLICATION_ID"
            value_from {
              secret_key_ref { name = kubernetes_secret.kuboard_oauth.metadata[0].name; key = "application-id" }
            }
          }
          env {
            name = "KUBOARD_GITLAB_CLIENT_SECRET"
            value_from {
              secret_key_ref { name = kubernetes_secret.kuboard_oauth.metadata[0].name; key = "client-secret" }
            }
          }

          volume_mount {
            name       = "kuboard-data"
            mount_path = "/data"
          }
          volume_mount {
            name       = "log-volume"
            mount_path = "/var/log/kuboard"
          }

          resources {
            requests = { cpu = "100m", memory = "256Mi" }
            limits   = { cpu = "500m", memory = "512Mi" }
          }
        }

        volume {
          name = "kuboard-data"
          persistent_volume_claim { claim_name = kubernetes_persistent_volume_claim.kuboard.metadata[0].name }
        }
        volume {
          name = "log-volume"
          host_path { path = "/var/log/kuboard"; type = "DirectoryOrCreate" }
        }
      }
    }
  }
}

resource "kubernetes_service_account" "kuboard" {
  metadata { name = "kuboard-admin"; namespace = "kuboard" }
}

resource "kubernetes_cluster_role_binding" "kuboard" {
  metadata { name = "kuboard-admin" }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.kuboard.metadata[0].name
    namespace = "kuboard"
  }
}

resource "kubernetes_secret" "kuboard_oauth" {
  metadata { name = "kuboard-gitlab-oauth"; namespace = "kuboard" }
  data = {
    "application-id" = var.gitlab_application_id
    "client-secret"  = var.gitlab_client_secret
  }
}

resource "kubernetes_persistent_volume_claim" "kuboard" {
  metadata { name = "kuboard-pvc"; namespace = "kuboard" }
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "gp3"
    resources { requests = { storage = "5Gi" } }
  }
}

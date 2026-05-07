# ============================================================
# terraform/modules/rocketmq/main.tf
# ============================================================

resource "kubernetes_namespace" "rocketmq" {
  metadata { name = "rocketmq" }
}

# NameServer
resource "kubernetes_stateful_set" "rocketmq_nameserver" {
  metadata {
    name      = "rocketmq-nameserver"
    namespace = kubernetes_namespace.rocketmq.metadata[0].name
  }

  spec {
    replicas     = 2
    service_name = "rocketmq-nameserver"

    selector { match_labels = { app = "rocketmq-nameserver" } }

    template {
      metadata { labels = { app = "rocketmq-nameserver" } }

      spec {
        container {
          name  = "nameserver"
          image = "apache/rocketmq:5.2.0"
          command = ["sh", "-c", "mqnamesrv"]

          port { container_port = 9876 }

          resources {
            requests = { cpu = "250m", memory = "512Mi" }
            limits   = { cpu = "500m", memory = "1Gi" }
          }

          volume_mount {
            name       = "store"
            mount_path = "/home/rocketmq/store"
          }
        }
      }
    }

    volume_claim_template {
      metadata { name = "store" }
      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = "gp3"
        resources { requests = { storage = "5Gi" } }
      }
    }
  }
}

resource "kubernetes_service" "rocketmq_nameserver" {
  metadata {
    name      = "rocketmq-nameserver"
    namespace = kubernetes_namespace.rocketmq.metadata[0].name
  }
  spec {
    selector = { app = "rocketmq-nameserver" }
    cluster_ip = "None"
    port { port = 9876; target_port = 9876 }
  }
}

# Broker
resource "kubernetes_stateful_set" "rocketmq_broker" {
  metadata {
    name      = "rocketmq-broker"
    namespace = kubernetes_namespace.rocketmq.metadata[0].name
  }

  spec {
    replicas     = var.broker_replica_count
    service_name = "rocketmq-broker"

    selector { match_labels = { app = "rocketmq-broker" } }

    template {
      metadata { labels = { app = "rocketmq-broker" } }

      spec {
        container {
          name  = "broker"
          image = "apache/rocketmq:5.2.0"
          command = ["sh", "-c", "mqbroker -n rocketmq-nameserver:9876 -c /etc/rocketmq/broker.conf"]

          port { container_port = 10911 }
          port { container_port = 10909 }

          resources {
            requests = { cpu = "500m",  memory = "1Gi" }
            limits   = { cpu = "2000m", memory = "4Gi" }
          }

          volume_mount {
            name       = "store"
            mount_path = "/home/rocketmq/store"
          }
        }
      }
    }

    volume_claim_template {
      metadata { name = "store" }
      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = "gp3"
        resources { requests = { storage = var.storage_size } }
      }
    }
  }

  depends_on = [kubernetes_stateful_set.rocketmq_nameserver]
}

resource "kubernetes_service" "rocketmq_broker" {
  metadata {
    name      = "rocketmq-broker"
    namespace = kubernetes_namespace.rocketmq.metadata[0].name
  }
  spec {
    selector = { app = "rocketmq-broker" }
    cluster_ip = "None"
    port { name = "vip"; port = 10911 }
    port { name = "ha";  port = 10912 }
  }
}

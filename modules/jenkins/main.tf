# ============================================================
# terraform/modules/jenkins/main.tf
# ============================================================

resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = "jenkins"
    labels = {
      app         = "jenkins"
      managed-by  = "terraform"
    }
  }
}

resource "kubernetes_persistent_volume_claim" "jenkins_home" {
  metadata {
    name      = "jenkins-home"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "gp3"

    resources {
      requests = {
        storage = var.jenkins_storage_size
      }
    }
  }
}

resource "helm_release" "jenkins" {
  name       = "jenkins"
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  version    = "5.1.5"
  namespace  = kubernetes_namespace.jenkins.metadata[0].name

  values = [
    yamlencode({
      controller = {
        adminUser     = var.jenkins_admin_user
        adminPassword = var.jenkins_admin_password

        ingress = {
          enabled          = true
          ingressClassName = "nginx"
          hostName         = var.jenkins_domain
          annotations = {
            "nginx.ingress.kubernetes.io/ssl-redirect"    = "true"
            "nginx.ingress.kubernetes.io/proxy-body-size" = "50m"
          }
          tls = [
            {
              secretName = "jenkins-tls"
              hosts      = [var.jenkins_domain]
            }
          ]
        }

        resources = {
          requests = { cpu = "500m",  memory = "512Mi" }
          limits   = { cpu = "2000m", memory = "2Gi"   }
        }

        javaOpts = "-Xms512m -Xmx1536m"

        installPlugins = [
          "kubernetes:4253.v7700d91739e5",
          "workflow-job:1400.v7fd111b_ec82f",
          "workflow-aggregator:600.vb_57cdd26fdd7",
          "git:5.2.1",
          "gitlab-plugin:1.8.1",
          "blueocean:1.27.14",
          "credentials-binding:657.v2b_19db_7d6e6d",
          "configuration-as-code:1810.v9b_98b_0ba_3f3b_",
          "docker-workflow:572.v950f58993843",
          "pipeline-utility-steps:2.16.2",
        ]

        JCasC = {
          defaultConfig = true
          configScripts = {
            welcome-message = "jenkins:\n  systemMessage: \"Jenkins on EKS — Managed by Terraform\"\n"
          }
        }
      }

      agent = {
        enabled = true
        resources = {
          requests = { cpu = "200m",  memory = "256Mi" }
          limits   = { cpu = "1000m", memory = "1Gi"   }
        }
      }

      persistence = {
        enabled       = true
        existingClaim = kubernetes_persistent_volume_claim.jenkins_home.metadata[0].name
        storageClass  = "gp3"
        size          = var.jenkins_storage_size
      }

      serviceAccount = {
        create = true
        name   = "jenkins"
      }

      prometheus = {
        enabled = true
      }
    })
  ]

  timeout = 600
  wait    = true

  depends_on = [
    kubernetes_namespace.jenkins,
    kubernetes_persistent_volume_claim.jenkins_home,
  ]
}

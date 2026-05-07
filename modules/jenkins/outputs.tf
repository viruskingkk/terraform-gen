# ============================================================
# terraform/modules/jenkins/outputs.tf
# ============================================================

output "jenkins_url" {
  description = "Jenkins 入口 URL"
  value       = "https://${var.jenkins_domain}"
}

output "jenkins_namespace" {
  description = "Jenkins 所在 Kubernetes Namespace"
  value       = kubernetes_namespace.jenkins.metadata[0].name
}

output "jenkins_service_account" {
  description = "Jenkins ServiceAccount 名稱（可用於 CI Pod RBAC）"
  value       = "jenkins"
}

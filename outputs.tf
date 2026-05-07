# ============================================================
# terraform/outputs.tf
# ============================================================

output "eks_cluster_name" {
  description = "EKS Cluster 名稱"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS API Server Endpoint"
  value       = module.eks.cluster_endpoint
  sensitive   = true
}

output "kubeconfig_command" {
  description = "更新 kubeconfig 指令"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "service_urls" {
  description = "各服務入口 URL"
  value = {
    harbor  = "https://${var.harbor_domain}"
    argocd  = "https://${var.argocd_domain}"
    kuboard = "https://${var.kuboard_domain}"
    kibana  = "https://${var.kibana_domain}"
    grafana = "https://${var.grafana_domain}"
    jenkins = "https://${var.jenkins_domain}"
  }
}

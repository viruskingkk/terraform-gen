# ============================================================
# terraform/variables.tf
# ============================================================

# ── 基礎設定 ─────────────────────────────────────────────────
variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "專案名稱（用於資源命名與 Tag）"
  type        = string
  default     = "gitops"
}

variable "environment" {
  description = "環境（production / staging / development）"
  type        = string
  default     = "production"
}

# ── EKS Node ──────────────────────────────────────────────────
variable "node_instance_type" {
  description = "EKS Node EC2 instance type"
  type        = string
  default     = "m5.large"
}

variable "node_desired_size" {
  type    = number
  default = 3
}

variable "node_min_size" {
  type    = number
  default = 2
}

variable "node_max_size" {
  type    = number
  default = 6
}

# ── 域名 ──────────────────────────────────────────────────────
variable "harbor_domain" {
  type    = string
  default = "harbor.yourdomain.com"
}

variable "argocd_domain" {
  type    = string
  default = "argocd.yourdomain.com"
}

variable "kuboard_domain" {
  type    = string
  default = "kuboard.yourdomain.com"
}

variable "kibana_domain" {
  type    = string
  default = "kibana.yourdomain.com"
}

variable "grafana_domain" {
  type    = string
  default = "grafana.yourdomain.com"
}

variable "jenkins_domain" {
  description = "Jenkins 對外域名"
  type        = string
  default     = "jenkins.yourdomain.com"
}

# ── GitLab ────────────────────────────────────────────────────
variable "gitlab_base_url" {
  type    = string
  default = "https://gitlab.yourdomain.com"
}

variable "gitlab_repo_url" {
  description = "ArgoCD GitOps Config Repo SSH URL"
  type        = string
  default     = "git@gitlab.yourdomain.com:gitops/config-repo.git"
}

# ── Secrets ───────────────────────────────────────────────────
variable "harbor_admin_password" {
  type      = string
  sensitive = true
}

variable "jenkins_admin_user" {
  description = "Jenkins 管理員帳號"
  type        = string
  default     = "admin"
}

variable "jenkins_admin_password" {
  description = "Jenkins 管理員密碼"
  type        = string
  sensitive   = true
}

variable "jenkins_storage_size" {
  description = "Jenkins home PVC 大小"
  type        = string
  default     = "20Gi"
}

variable "gitlab_kuboard_app_id" {
  type      = string
  sensitive = true
}

variable "gitlab_kuboard_secret" {
  type      = string
  sensitive = true
}

variable "gitlab_grafana_client_id" {
  type      = string
  sensitive = true
}

variable "gitlab_grafana_client_secret" {
  type      = string
  sensitive = true
}

variable "alertmanager_email" {
  description = "告警通知收件 Email"
  type        = string
  default     = "devops@yourdomain.com"
}

variable "slack_webhook_url" {
  type      = string
  sensitive = true
  default   = ""
}

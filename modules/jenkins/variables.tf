# ============================================================
# terraform/modules/jenkins/variables.tf
# ============================================================

variable "jenkins_domain" {
  description = "Jenkins 對外域名，例如 jenkins.yourdomain.com"
  type        = string
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
  description = "Jenkins home 目錄 PVC 大小（gp3）"
  type        = string
  default     = "20Gi"
}

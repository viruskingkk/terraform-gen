variable "grafana_domain"        { type = string }
variable "gitlab_base_url"       { type = string }
variable "gitlab_client_id"      { type = string; sensitive = true }
variable "gitlab_client_secret"  { type = string; sensitive = true }
variable "alertmanager_email"    { type = string }
variable "slack_webhook_url"     { type = string; sensitive = true; default = "" }

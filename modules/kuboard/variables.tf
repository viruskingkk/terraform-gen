variable "kuboard_domain"        { type = string }
variable "gitlab_base_url"       { type = string }
variable "gitlab_application_id" { type = string; sensitive = true }
variable "gitlab_client_secret"  { type = string; sensitive = true }

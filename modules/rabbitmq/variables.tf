variable "password"      { type = string; sensitive = true }
variable "storage_size"  { type = string; default = "10Gi" }
variable "replica_count" { type = number; default = 3 }

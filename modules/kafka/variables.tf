variable "broker_count"       { type = number; default = 3 }
variable "storage_size"       { type = string; default = "10Gi" }
variable "mode"               { type = string; default = "kraft" } # kraft / zk
variable "zookeeper_enabled"  { type = bool;   default = false }

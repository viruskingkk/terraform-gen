output "kibana_url"       { value = "https://${var.kibana_domain}" }
output "elasticsearch_url"{ value = "http://elasticsearch-master.logging.svc.cluster.local:9200" }

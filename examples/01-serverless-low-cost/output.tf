output "serverless_low_cost_cache_name" {
  description = "Name of the low-cost serverless ElastiCache."
  value       = module.elasticache_serverless_low_cost.serverless_cache_name
}

output "serverless_low_cost_endpoint" {
  description = "Endpoint of the low-cost serverless ElastiCache."
  value       = module.elasticache_serverless_low_cost.serverless_cache_endpoint_address
}

output "serverless_low_cost_port" {
  description = "Port of the low-cost serverless ElastiCache."
  value       = module.elasticache_serverless_low_cost.serverless_cache_endpoint_port
}
output "serverless_limited_cache_name" {
  description = "Name of the serverless ElastiCache with specific limits."
  value       = module.elasticache_serverless_limited.serverless_cache_name
}

output "serverless_limited_endpoint" {
  description = "Endpoint of the serverless ElastiCache with specific limits."
  value       = module.elasticache_serverless_limited.serverless_cache_endpoint_address
}

output "serverless_limited_port" {
  description = "Port of the serverless ElastiCache with specific limits."
  value       = module.elasticache_serverless_limited.serverless_cache_endpoint_port
}
output "traditional_cluster_config_endpoint" {
  description = "Configuration Endpoint for the traditional clustered ElastiCache."
  value       = module.elasticache_traditional_clustered.replication_group_primary_endpoint_address
}

output "traditional_cluster_sg_id" {
  description = "Security Group ID for the traditional clustered ElastiCache."
  value       = module.elasticache_traditional_clustered.elasticache_security_group_id
}

output "traditional_cluster_generated_auth_token" {
  description = "Generated Auth Token (if any). This is sensitive."
  value       = module.elasticache_traditional_clustered.replication_group_generated_auth_token
  sensitive   = true
}
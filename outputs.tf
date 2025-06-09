output "elasticache_security_group_id" {
  description = "The ID of the security group created for ElastiCache."
  value       = aws_security_group.this.id
}

output "elasticache_subnet_group_name" {
  description = "The name of the ElastiCache subnet group."
  value       = aws_elasticache_subnet_group.this.name
}

// Serverless Outputs
output "serverless_cache_arn" {
  description = "ARN of the Serverless Cache."
  value       = local.is_serverless ? one(aws_elasticache_serverless_cache.this[*].arn) : null
}

output "serverless_cache_name" {
  description = "Name of the Serverless Cache."
  value       = local.is_serverless ? one(aws_elasticache_serverless_cache.this[*].name) : null
}

output "serverless_cache_endpoint_address" {
  description = "Endpoint address for the Serverless Cache."
  value       = local.is_serverless ? (length(one(aws_elasticache_serverless_cache.this[*].endpoint)) > 0 ? one(aws_elasticache_serverless_cache.this[*].endpoint)[0].address : null) : null
}

output "serverless_cache_endpoint_port" {
  description = "Endpoint port for the Serverless Cache."
  value       = local.is_serverless ? (length(one(aws_elasticache_serverless_cache.this[*].endpoint)) > 0 ? one(aws_elasticache_serverless_cache.this[*].endpoint)[0].port : null) : null
}

output "serverless_cache_reader_endpoint_address" {
  description = "Reader endpoint address for the Serverless Cache."
  value       = local.is_serverless && length(one(aws_elasticache_serverless_cache.this[*].reader_endpoint)) > 0 ? one(aws_elasticache_serverless_cache.this[*].reader_endpoint)[0].address : null
}

output "serverless_cache_reader_endpoint_port" {
  description = "Reader endpoint port for the Serverless Cache."
  value       = local.is_serverless && length(one(aws_elasticache_serverless_cache.this[*].reader_endpoint)) > 0 ? one(aws_elasticache_serverless_cache.this[*].reader_endpoint)[0].port : null
}

// Traditional Replication Group Outputs
output "replication_group_id" {
  description = "ID of the Traditional ElastiCache Replication Group."
  value       = local.is_traditional ? one(aws_elasticache_replication_group.this[*].id) : null
}

output "replication_group_arn" {
  description = "ARN of the Traditional ElastiCache Replication Group."
  value       = local.is_traditional ? one(aws_elasticache_replication_group.this[*].arn) : null
}

output "replication_group_primary_endpoint_address" {
  description = "Primary endpoint address for the Traditional ElastiCache Replication Group. For cluster mode enabled, this is the configuration endpoint."
  value       = local.is_traditional ? one(aws_elasticache_replication_group.this[*].primary_endpoint_address) : null
}

output "replication_group_reader_endpoint_address" {
  description = "Reader endpoint address for the Traditional ElastiCache Replication Group (if applicable, not for cluster mode enabled or single node)."
  value       = local.is_traditional && !var.cluster_mode_enabled && var.replicas_per_node_group > 0 ? one(aws_elasticache_replication_group.this[*].reader_endpoint_address) : (local.is_traditional && var.cluster_mode_enabled ? "N/A for Cluster Mode (use primary_endpoint_address)" : (local.is_traditional && var.replicas_per_node_group == 0 ? "N/A for single node" : null))
}

output "replication_group_member_clusters" {
  description = "List of member cluster IDs in the Traditional ElastiCache Replication Group."
  value       = local.is_traditional ? one(aws_elasticache_replication_group.this[*].member_clusters) : null
}

output "replication_group_auth_token_enabled" {
  description = "Indicates if an auth_token is configured for the traditional replication group."
  value       = local.is_traditional && local.effective_auth_token != null
  sensitive   = true
}

output "replication_group_generated_auth_token" {
  description = "The generated auth token if one was created by the module. Store this securely. N/A if auth_token was provided by the user."
  value       = local.is_traditional && var.transit_encryption_enabled && var.auth_token == null ? one(random_password.auth_token[*].result) : "N/A (token provided by user or not applicable)"
  sensitive   = true
}

output "replication_group_parameter_group_name" {
  description = "Name of the parameter group used by the traditional replication group."
  value       = local.is_traditional ? one(aws_elasticache_parameter_group.this[*].name) : null
}

// Global Replication Group Outputs
output "global_replication_group_id" {
  description = "ID of the Global Replication Group, if created."
  value       = local.is_traditional && var.create_global_replication_group ? one(aws_elasticache_global_replication_group.this[*].id) : null
}

// Standalone ElastiCache Cluster Outputs
output "standalone_cluster_id_output" {
  description = "ID of the standalone ElastiCache cluster (aws_elasticache_cluster resource), if created."
  value       = var.create_standalone_redis_cluster_resource ? one(aws_elasticache_cluster.standalone[*].id) : null
}

output "standalone_cluster_cache_nodes" {
  description = "List of cache nodes in the standalone cluster."
  value       = var.create_standalone_redis_cluster_resource ? one(aws_elasticache_cluster.standalone[*].cache_nodes) : null
}

output "standalone_cluster_configuration_endpoint" {
  description = "Configuration endpoint for the standalone cluster (primary node endpoint)."
  value       = var.create_standalone_redis_cluster_resource ? one(aws_elasticache_cluster.standalone[*].configuration_endpoint) : null
}
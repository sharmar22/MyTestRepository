locals {
  is_serverless   = var.deployment_option == "serverless"
  is_traditional  = var.deployment_option == "traditional"

  effective_auth_token = local.is_traditional && var.transit_encryption_enabled && var.auth_token == null ? (
    one(random_password.auth_token[*].result) # Use one() if random_password has count
  ) : var.auth_token

  # For traditional non-cluster mode (cluster_mode_enabled = false)
  # num_cache_clusters is 1 (primary) + number of replicas
  traditional_non_cluster_num_cache_clusters = !var.cluster_mode_enabled ? (1 + var.replicas_per_node_group) : null

  # Automatic failover for traditional non-cluster mode requires >1 cache cluster (i.e., replicas > 0)
  traditional_non_cluster_auto_failover = !var.cluster_mode_enabled ? (
    var.automatic_failover_enabled && var.replicas_per_node_group > 0
  ) : null

  # Multi-AZ for traditional depends on failover capabilities or cluster setup
  effective_multi_az_enabled = local.is_traditional ? (
    var.multi_az_enabled && (
      (var.cluster_mode_enabled && var.replicas_per_node_group > 0) || # Cluster mode with replicas can be multi-AZ
      (!var.cluster_mode_enabled && local.traditional_non_cluster_auto_failover) || # Non-cluster mode needs failover
      (!var.cluster_mode_enabled && var.replicas_per_node_group == 0 && var.multi_az_enabled) # Single node explicitly Multi-AZ
    )
  ) : false

  # KMS Key ID for encryption
  # Serverless is always encrypted at rest. Uses AWS-owned key if kms_key_id is null.
  # Traditional uses at_rest_encryption_enabled flag.
  traditional_kms_key_id = local.is_traditional && var.at_rest_encryption_enabled ? var.kms_key_id : null
  serverless_kms_key_id  = local.is_serverless ? var.kms_key_id : null # Pass null for AWS-owned key

  # Consolidated snapshot settings
  serverless_effective_snapshot_retention  = max(1, var.snapshot_retention_days) # Serverless min is 1
  traditional_effective_snapshot_retention = var.snapshot_retention_days          # Traditional can be 0 to disable

  # Common tags applied to all resources managed by this module
  module_tags = merge(
    {
      "AIT":                 var.ait_tag,
      "Environment":         var.environment_tag,
      "RTO":                 var.rto_tag,
      "TerraformModule":     "terraform-aws-elasticache-redis",
      "ElastiCache:Name":    var.name_prefix,
      "ElastiCache:Deployment": var.deployment_option
    },
    var.custom_tags
  )
}
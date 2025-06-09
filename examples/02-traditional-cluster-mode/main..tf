
// examples/02-traditional-cluster-mode/main.tf
module "elasticache_traditional_clustered" {
  source = "../../"

  name_prefix     = "trad-clust"
  ait_tag         = "AITTRDCLUS"
  environment_tag = "staging"
  rto_tag         = "4h"

  deployment_option    = "traditional"
  cluster_mode_enabled = true // This module input tells our module to set num_node_groups etc.

  vpc_id     = data.aws_vpc.default.id
  subnet_ids = slice(data.aws_subnets.private.ids, 0, min(3, length(data.aws_subnets.private.ids)))

  allowed_security_group_ids = [aws_security_group.application_sg.id]
  kms_key_id                 = aws_kms_key.elasticache_cmek.arn

  engine_version         = "7.0"    // Or "7.0" - ensure this aligns with the family
  parameter_group_family = "redis7"   // <--- KEY CHANGE: Use the base family name

  #node_type              = "cache.m6g.large"
  node_type              = "cache.t3.micro"  
  num_node_groups         = 2         // Used by module because cluster_mode_enabled = true
  replicas_per_node_group = 1         // Used by module because cluster_mode_enabled = true

  automatic_failover_enabled = true
  multi_az_enabled           = true

  snapshot_retention_days   = 7
  # Make sure there is no overlap of backup and snapshot
  daily_snapshot_window_utc = "06:30-08:30"

  # If you need to set the "cluster-enabled" parameter *within* the "redis7" group,
  # you can do it here. However, for ElastiCache Redis, simply configuring the
  # replication group with num_node_groups > 1 is usually what enables cluster mode behavior.
  # Check AWS docs if you find this parameter is explicitly required for some functionality.
  parameter_group_parameters = [
     { name = "cluster-enabled", value = "yes" } 
   ]
  
  custom_tags = {
    CostCenter = "CC123"
    Project    = "Phoenix"
  }
}


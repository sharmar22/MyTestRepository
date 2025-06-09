resource "random_password" "auth_token" {
  count = local.is_traditional && var.transit_encryption_enabled && var.auth_token == null ? 1 : 0

  length           = 20
  special          = false
  override_special = "!#%+,-.<>=?@^_:"
}

resource "aws_elasticache_subnet_group" "this" {
  name        = "${var.name_prefix}-sng"
  description = "ElastiCache subnet group for ${var.name_prefix}"
  subnet_ids  = var.subnet_ids
  tags        = local.module_tags
}

resource "aws_security_group" "this" {
  name        = "${var.name_prefix}-sg"
  description = "Security group for ElastiCache ${var.name_prefix}"
  vpc_id      = var.vpc_id
  tags        = local.module_tags

  dynamic "ingress" {
    for_each = toset(var.allowed_security_group_ids)
    content {
      description     = "Allow Redis from SG ${ingress.value}"
      from_port       = 6379
      to_port         = 6379
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
  }

  dynamic "ingress" {
    for_each = toset(var.allowed_cidr_blocks)
    content {
      description = "Allow Redis from CIDR ${ingress.value}"
      from_port   = 6379
      to_port     = 6379
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

##
resource "aws_elasticache_serverless_cache" "this" {
  count = local.is_serverless ? 1 : 0

  name                 = var.serverless_cache_name != "" ? var.serverless_cache_name : "${var.name_prefix}-serverless"
  engine               = var.serverless_engine
  major_engine_version = var.serverless_major_engine_version
  subnet_ids           = var.subnet_ids
  security_group_ids   = [aws_security_group.this.id]
  kms_key_id           = local.serverless_kms_key_id

  dynamic "cache_usage_limits" {
    for_each = var.serverless_cache_usage_limits != null ? [var.serverless_cache_usage_limits] : []
    content {
      dynamic "data_storage" {
        for_each = lookup(cache_usage_limits.value, "data_storage", null) != null ? [lookup(cache_usage_limits.value, "data_storage")] : []
        content {
          maximum = data_storage.value.maximum
          unit    = data_storage.value.unit
        }
      }
      dynamic "ecpu_per_second" {
        for_each = lookup(cache_usage_limits.value, "ecpu_per_second", null) != null ? [lookup(cache_usage_limits.value, "ecpu_per_second")] : []
        content {
          maximum = ecpu_per_second.value.maximum
        }
      }
    }
  }

  # Corrected: Extract the start time from the window for Serverless daily_snapshot_time
  daily_snapshot_time      = split("-", var.daily_snapshot_window_utc)[0] 
  snapshot_retention_limit = local.serverless_effective_snapshot_retention
  tags                     = local.module_tags
}
##

// In your module's main.tf
resource "aws_elasticache_parameter_group" "this" {
  count = local.is_traditional ? 1 : 0

  name        = "${var.name_prefix}-${replace(var.parameter_group_family, ".", "-")}-pg"
  family      = var.parameter_group_family // This will receive "redis7" or "redis6.x" etc.
  description = "Custom ElastiCache parameter group for ${var.name_prefix} (Family: ${var.parameter_group_family})"
  tags        = local.module_tags

  dynamic "parameter" {
    for_each = var.parameter_group_parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }
}

resource "aws_elasticache_replication_group" "this" {
  count = local.is_traditional ? 1 : 0

  replication_group_id = var.replication_group_id_prefix != "" ? "${var.replication_group_id_prefix}-${var.name_prefix}-rg" : "${var.name_prefix}-rg"
  description          = var.replication_group_description

  engine                     = "redis"
  engine_version             = var.engine_version
  parameter_group_name       = one(aws_elasticache_parameter_group.this[*].name)
  port                       = 6379
  node_type                  = var.node_type
  subnet_group_name          = aws_elasticache_subnet_group.this.name
  security_group_ids         = [aws_security_group.this.id]
  at_rest_encryption_enabled = var.at_rest_encryption_enabled
  transit_encryption_enabled = var.transit_encryption_enabled
  kms_key_id                 = local.traditional_kms_key_id
  auth_token                 = local.effective_auth_token

  # If cluster_mode_enabled is true, set num_node_groups and replicas_per_node_group
  num_node_groups         = var.cluster_mode_enabled ? var.num_node_groups : null
  replicas_per_node_group = var.cluster_mode_enabled ? var.replicas_per_node_group : null
  
  # If cluster_mode_enabled is false, set num_cache_clusters
  num_cache_clusters = !var.cluster_mode_enabled ? local.traditional_non_cluster_num_cache_clusters : null
  
  automatic_failover_enabled = var.cluster_mode_enabled ? (var.replicas_per_node_group > 0 && var.automatic_failover_enabled) : local.traditional_non_cluster_auto_failover

  multi_az_enabled = local.effective_multi_az_enabled
  
  snapshot_retention_limit = local.traditional_effective_snapshot_retention
  snapshot_window          = var.daily_snapshot_window_utc
  maintenance_window       = var.maintenance_window
  apply_immediately        = var.apply_immediately
  tags                     = local.module_tags

  lifecycle {
    precondition {
      condition     = !(var.auth_token != null && !var.transit_encryption_enabled)
      error_message = "For Traditional ElastiCache, if an auth_token is provided, transit_encryption_enabled must be true."
    }
    precondition {
      condition     = !(var.transit_encryption_enabled == false && var.auth_token != null)
      error_message = "For Traditional ElastiCache, auth_token cannot be set if transit_encryption_enabled is false. ElastiCache Redis requires TLS for AUTH."
    }
    ignore_changes = [
      num_cache_clusters,
      num_node_groups,
      replicas_per_node_group,
    ]
  }
}

resource "aws_elasticache_global_replication_group" "this" {
  count = local.is_traditional && var.create_global_replication_group ? 1 : 0

  global_replication_group_id_suffix = var.global_replication_group_id_suffix
  primary_replication_group_id       = one(aws_elasticache_replication_group.this[*].id)
  engine_version                     = var.engine_version
}

resource "aws_elasticache_cluster" "standalone" {
  count = var.create_standalone_redis_cluster_resource ? 1 : 0

  cluster_id           = var.standalone_cluster_id != "" ? var.standalone_cluster_id : "${var.name_prefix}-standalone-cl"
  engine               = "redis"
  node_type            = var.standalone_node_type
  num_cache_nodes      = 1
  engine_version       = var.standalone_engine_version
  parameter_group_name = var.standalone_parameter_group_name
  subnet_group_name    = aws_elasticache_subnet_group.this.name
  security_group_ids   = [aws_security_group.this.id]
  tags                 = local.module_tags
}
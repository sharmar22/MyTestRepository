variable "name_prefix" {
  description = "A prefix used for naming resources. Ensures uniqueness and context. Example: 'myapp-prod-cache'."
  type        = string
}

variable "deployment_option" {
  description = "Deployment model for ElastiCache Redis. Options: 'serverless' or 'traditional'."
  type        = string
  default     = "serverless"
  validation {
    condition     = contains(["serverless", "traditional"], var.deployment_option)
    error_message = "Valid options for deployment_option are 'serverless' or 'traditional'."
  }
}

// --- Common Tags ---
variable "ait_tag" {
  description = "Application Identification Token (AIT) tag."
  type        = string
}

variable "environment_tag" {
  description = "Environment tag (e.g., dev, staging, prod)."
  type        = string
}

variable "rto_tag" {
  description = "Recovery Time Objective (RTO) tag."
  type        = string
}

variable "custom_tags" {
  description = "A map of additional custom tags to apply to all resources."
  type        = map(string)
  default     = {}
}

// --- Networking ---
variable "vpc_id" {
  description = "The ID of the VPC where ElastiCache will be deployed."
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnet IDs for the ElastiCache subnet group. Required for both serverless and traditional. Provide subnets from different AZs for high availability."
  type        = list(string)
  validation {
    condition     = length(var.subnet_ids) >= 1
    error_message = "At least one subnet ID must be provided."
  }
}

variable "allowed_security_group_ids" {
  description = "List of security group IDs that are allowed to access ElastiCache on port 6379."
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks that are allowed to access ElastiCache on port 6379."
  type        = list(string)
  default     = []
}

// --- Security & Encryption ---
variable "kms_key_id" {
  description = "The ARN of the AWS KMS Customer Managed Key (CMK) to use for at-rest encryption. Serverless is always encrypted at rest (uses AWS-owned key if this is null). For Traditional, if at_rest_encryption_enabled is true, this key is used for CMEK (AWS-managed if null)."
  type        = string
  default     = null
}

variable "transit_encryption_enabled" {
  description = "For Traditional: Enable in-transit encryption (TLS). Strongly recommended and required if an auth_token is used. For Serverless: This is ignored as Serverless connections are always TLS encrypted."
  type        = bool
  default     = true
}

// --- Snapshot Configuration (Consolidated) ---
variable "snapshot_retention_days" {
  description = "Number of days to retain automated snapshots. For Traditional, 0 disables snapshots. For Serverless, the minimum is 1 day (if 0 is provided, the module will use 1)."
  type        = number
  default     = 7
  validation {
    condition     = var.snapshot_retention_days >= 0 && var.snapshot_retention_days <= 35
    error_message = "Snapshot retention period must be between 0 and 35 days."
  }
}

// --- Serverless Specific ---
variable "serverless_cache_name" {
  description = "The user-defined name for the ElastiCache Serverless cache. If not provided, one will be generated using name_prefix. Must be unique."
  type        = string
  default     = ""
}

variable "serverless_engine" {
  description = "The engine for serverless cache (currently only 'redis')."
  type        = string
  default     = "redis"
  validation {
    condition     = var.serverless_engine == "redis"
    error_message = "Only 'redis' is supported for serverless_engine."
  }
}

variable "serverless_major_engine_version" {
  description = "The major engine version for the serverless cache (e.g., '7')."
  type        = string
  default     = "7"
}

variable "serverless_cache_usage_limits" {
  description = "Configuration for serverless cache usage limits. See AWS docs for ElastiCacheServerless.CacheUsageLimits. Set to `null` to use AWS defaults."
  type = object({
    data_storage = optional(object({
      maximum = number # In GB
      unit    = string # GB
    }))
    ecpu_per_second = optional(object({
      maximum = number
    }))
  })
  default = null
}

// --- Traditional (Replication Group / Cluster) Specific ---
variable "replication_group_id_prefix" {
  description = "Prefix for the replication group ID for traditional Redis. Final ID: <prefix>-<name_prefix>-rg. If empty, <name_prefix>-rg is used."
  type        = string
  default     = ""
}

variable "replication_group_description" {
  description = "Description for the replication group."
  type        = string
  default     = "Managed by Terraform"
}

variable "engine_version" {
  description = "Redis engine version for traditional deployment (e.g., '6.x', '7.0', '7.1')."
  type        = string
  default     = "7.1"
}

variable "parameter_group_family" {
  description = "Parameter group family for traditional Redis (e.g., 'redis6.x', 'redis7'). Should align with engine_version."
  type        = string
  default     = "redis7"
}


variable "node_type" {
  description = "The cache node type for traditional deployment (e.g., 'cache.t3.small', 'cache.m6g.large')."
  type        = string
  default     = "cache.t3.small"
}

variable "cluster_mode_enabled" {
  description = "Set to true to enable Redis Cluster Mode for traditional deployment."
  type        = bool
  default     = false
}

variable "num_node_groups" {
  description = "Number of node groups (shards) for Redis (cluster mode enabled)."
  type        = number
  default     = 1
}

variable "replicas_per_node_group" {
  description = "Number of read replicas per node group (shard) for traditional Redis. Set to 0 for a single-node primary."
  type        = number
  default     = 1
}

variable "automatic_failover_enabled" {
  description = "For Traditional: Specifies if a read-only replica is automatically promoted on primary failure. Requires replicas_per_node_group > 0."
  type        = bool
  default     = true
}

variable "multi_az_enabled" {
  description = "For Traditional: Specifies whether to enable Multi-AZ Support. Typically true if automatic_failover_enabled is true."
  type        = bool
  default     = true
}

variable "at_rest_encryption_enabled" {
  description = "For Traditional: Enable at-rest encryption. If true and kms_key_id is provided, CMEK is used. If kms_key_id is null, an AWS-managed key is used. Serverless is always encrypted at rest."
  type        = bool
  default     = true
}

variable "auth_token" {
  description = "For Traditional: The password (auth token). Min 16, Max 128 alphanumeric characters. If null and transit_encryption_enabled is true, a random one is generated."
  type        = string
  default     = null
  sensitive   = true
  validation {
    condition     = var.auth_token == null || (length(var.auth_token) >= 16 && length(var.auth_token) <= 128 && can(regex("^[a-zA-Z0-9]+$", var.auth_token)))
    error_message = "Auth token must be 16-128 alphanumeric characters."
  }
}

variable "maintenance_window" {
  description = "For Traditional: Weekly time range for system maintenance. Format: ddd:hh24:mi-ddd:hh24:mi."
  type        = string
  default     = "sun:03:00-sun:04:00"
}

variable "apply_immediately" {
  description = "For Traditional: Specifies whether modifications are applied immediately or during the next maintenance window."
  type        = bool
  default     = false
}

variable "parameter_group_parameters" {
  description = "For Traditional: A list of parameters to apply to the custom parameter group. If `cluster_mode_enabled` is true, you MUST include `{ name = \"cluster-enabled\", value = \"yes\" }` in this list for compatible families like 'redis6.x' or 'redis7'."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}


// --- Global Replication Group (Traditional Specific) ---
variable "create_global_replication_group" {
  description = "Set to true to create a global replication group (traditional only)."
  type        = bool
  default     = false
}

variable "global_replication_group_id_suffix" {
  description = "Suffix for the Global Replication Group ID (traditional only)."
  type        = string
  default     = "global-redis"
}

// --- Optional aws_elasticache_cluster (single node, non-replicated, basic Redis) ---
variable "create_standalone_redis_cluster_resource" {
  description = "Set to true to create a standalone aws_elasticache_cluster (single node Redis, non-replicated). Use with caution; 'traditional' deployment_option with replication_group is generally preferred for Redis."
  type        = bool
  default     = false
}

variable "standalone_cluster_id" {
  description = "ID for the standalone ElastiCache cluster."
  type        = string
  default     = ""
}

variable "standalone_node_type" {
  description = "Node type for standalone cluster (e.g., 'cache.t3.micro')."
  type        = string
  default     = "cache.t3.micro"
}

variable "standalone_engine_version" {
  description = "Engine version for standalone cluster (e.g., '7.0')."
  type        = string
  default     = "7.0"
}

variable "standalone_parameter_group_name" {
  description = "Parameter group name for standalone cluster (e.g., 'default.redis7')."
  type        = string
  default     = "default.redis7"
}



variable "daily_snapshot_window_utc" {
  description = "The daily time range (in UTC) during which ElastiCache begins taking a daily snapshot. Format: HH:MM-HH:MM (e.g., '03:00-04:00'). For Serverless ElastiCache, only the start time of this window is used." # Added clarification
  type        = string
  default     = "03:00-04:00"
  validation {
    condition     = can(regex("^([01][0-9]|2[0-3]):[0-5][0-9]-([01][0-9]|2[0-3]):[0-5][0-9]$", var.daily_snapshot_window_utc))
    error_message = "daily_snapshot_window_utc must be in HH:MM-HH:MM format."
  }
}



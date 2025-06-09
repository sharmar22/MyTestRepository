
## Example Files (`terraform-aws-elasticache-redis/examples/`)
###The common `providers.tf` for all examples remains the same as provided in the previous response. I will regenerate the `main.tf` and `outputs.tf` for each example to ensure they are perfectly aligned with the final module structure.
### `examples/01-serverless-low-cost/`
#### `examples/01-serverless-low-cost/main.tf`
###terraform
module "elasticache_serverless_low_cost" {
  source = "../../" // Path to the local module

  name_prefix     = "srvls-lcost"
  ait_tag         = "AITSLSLC"
  environment_tag = "test"
  rto_tag         = "7d" // Relaxed RTO for test

  # deployment_option = "serverless" # This is the default

  vpc_id     = data.aws_vpc.default.id
  subnet_ids = slice(data.aws_subnets.private.ids, 0, min(2, length(data.aws_subnets.private.ids))) # Ensure at least 2 subnets

  allowed_security_group_ids = [aws_security_group.application_sg.id]

  kms_key_id                    = null # Uses AWS-owned key
  serverless_cache_usage_limits = null # Uses AWS defaults

  snapshot_retention_days   = 1 # Min for Serverless
  daily_snapshot_window_utc = "02:00-04:00"

  custom_tags = {
    Purpose = "LowCostTest"
  }
}
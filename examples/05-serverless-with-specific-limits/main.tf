module "elasticache_serverless_limited" {
  source = "../../"

  name_prefix     = "srvls-limit"
  ait_tag         = "AITSLSLIM"
  environment_tag = "perf-test"
  rto_tag         = "48h"

  vpc_id     = data.aws_vpc.default.id
  subnet_ids = slice(data.aws_subnets.private.ids, 0, min(2, length(data.aws_subnets.private.ids)))

  allowed_security_group_ids = [aws_security_group.application_sg.id]
  kms_key_id                 = aws_kms_key.elasticache_cmek.arn

  serverless_cache_name = "limited-serverless-redis"
  serverless_cache_usage_limits = {
    data_storage = {
      maximum = 50
      unit    = "GB"
    }
    ecpu_per_second = {
      maximum = 2000
    }
  }
  
  snapshot_retention_days   = 30
  # Using module default for daily_snapshot_window_utc = "04:00-05:00"
  
  custom_tags = { TestPhase = "Load" }
}
// test-pg.tf

provider "aws" {
  region = "us-east-1" // CHANGE TO YOUR ACTUAL AWS REGION
}

resource "aws_elasticache_parameter_group" "test_cluster_pg" {
  name        = "my-test-redis7-cluster-pg"    // Simple, valid name
  family      = "redis7"            // The family string we are testing
  description = "Test for redis7.cluster.on family"

  // Optional: Add a common parameter if you want to test that too
  // parameter {
  //   name  = "cluster-enabled" // This is a common one for cluster mode groups
  //   value = "yes"
  // }
}

output "test_pg_id" {
  value = aws_elasticache_parameter_group.test_cluster_pg.id
}

output "test_pg_arn" {
  value = aws_elasticache_parameter_group.test_cluster_pg.arn
}

output "test_pg_family" {
  value = aws_elasticache_parameter_group.test_cluster_pg.family
}
// examples/01-serverless-low-cost/providers.tf

provider "aws" {
  region = "us-east-1" // Or your desired AWS region
}

// Example: Create a KMS key for ElastiCache encryption (CMEK)
// For the low-cost serverless example, we set kms_key_id = null in main.tf,
// so this KMS key resource might not be strictly necessary for *this specific example* if it's not used.
// However, it's good to have for other examples that might use it.
// If you want this example to have ZERO external dependencies for KMS, you can comment this out
// AND ensure kms_key_id = null in the module call in main.tf.
resource "aws_kms_key" "elasticache_cmek" {
  description             = "KMS key for ElastiCache CMEK example"
  deletion_window_in_days = 7
  tags = {
    Name = "elasticache-example-cmek"
  }
}

// Example: Get default VPC and subnets
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  # Ideally, filter for private subnets in different AZs.
  # For simplicity, this takes the first few available.
}

// Example: Security group for an application that needs to access ElastiCache
resource "aws_security_group" "application_sg" {
  name        = "example-app-sg-sls-lowcost" # Unique name for this example's SG
  description = "Security group for an example application server (low-cost serverless example)"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Allow SSH (for testing from bastion/your IP)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # WARNING: Open to all. Restrict in production.
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "example-app-sg-sls-lowcost"
    Example = "01-serverless-low-cost"
  }
}
locals {
  common_tags = {
    Project     = var.project_name
    Environment = "shared"
    Owner       = var.owner
    ManagedBy   = "Terraform"
  }
}

provider "aws" {
  region              = var.aws_region
  allowed_account_ids = [var.expected_account_id]

  default_tags {
    tags = local.common_tags
  }
}

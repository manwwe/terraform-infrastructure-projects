locals {
  state_bucket_name = "${var.project_name}-tfstate-${data.aws_caller_identity.current.account_id}"

  common_tags = {
    Project     = var.project_name
    Environment = "shared"
    ManagedBy   = "terraform"
    Repository  = "terraform-infrastructure-projects"
    Owner       = var.owner
  }
}

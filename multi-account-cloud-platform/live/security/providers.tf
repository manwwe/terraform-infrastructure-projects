provider "aws" {
  region              = var.aws_region
  allowed_account_ids = [var.security_account_id]
  assume_role {
    role_arn     = "arn:aws:iam::${var.security_account_id}:role/OrganizationAccountAccessRole"
    session_name = "terraform-security"
  }
  default_tags {
    tags = {
      Project     = "multi-account-cloud-platform"
      Environment = "security"
      Owner       = var.owner
      ManagedBy   = "Terraform"
    }
  }
}

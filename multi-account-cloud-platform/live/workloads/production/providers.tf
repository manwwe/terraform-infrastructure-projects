provider "aws" {
  region              = var.aws_region
  allowed_account_ids = [var.production_account_id]

  assume_role {
    role_arn     = "arn:aws:iam::${var.production_account_id}:role/OrganizationAccountAccessRole"
    session_name = "terraform-production"
  }

  default_tags {
    tags = local.tags
  }
}

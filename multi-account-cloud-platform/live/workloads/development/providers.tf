provider "aws" {
  region              = var.aws_region
  allowed_account_ids = [var.development_account_id]

  assume_role {
    role_arn     = "arn:aws:iam::${var.development_account_id}:role/OrganizationAccountAccessRole"
    session_name = "terraform-development"
  }

  default_tags {
    tags = local.tags
  }
}

provider "aws" {
  region              = var.aws_region
  allowed_account_ids = [var.shared_services_account_id]

  assume_role {
    role_arn     = "arn:aws:iam::${var.shared_services_account_id}:role/OrganizationAccountAccessRole"
    session_name = "terraform-shared-services"
  }

  default_tags {
    tags = local.tags
  }
}

locals {
  tags = {
    Project     = "multi-account-cloud-platform"
    Environment = "production"
    Owner       = var.owner
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
  tags            = local.tags
}

module "deployment_roles" {
  source = "../../../modules/deployment-role"

  name_prefix                = "macp-production"
  trusted_aws_principal_arns = ["arn:aws:iam::${var.management_account_id}:root"]
  github_oidc_provider_arn   = aws_iam_openid_connect_provider.github.arn
  github_subjects = [
    "repo:${var.github_repository}:pull_request",
    "repo:${var.github_repository}:environment:production"
  ]
  tags = local.tags
}

module "account_baseline" {
  source = "../../../modules/account-baseline"

  account_alias                 = "macp-production"
  config_bucket_name            = var.config_bucket_name
  config_bucket_key_prefix      = "AWSConfig"
  config_kms_key_arn            = var.config_kms_key_arn
  include_global_resource_types = false
  tags                          = local.tags
}

module "vpc" {
  source = "../../../modules/vpc"

  name               = "macp-production"
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  nat_gateway_mode   = "per_az"
  tags               = local.tags
}

resource "aws_route53_zone_association" "private_parent" {
  count = var.private_zone_id == null ? 0 : 1

  zone_id    = var.private_zone_id
  vpc_id     = module.vpc.vpc_id
  vpc_region = var.aws_region
}

resource "aws_budgets_budget" "monthly" {
  name         = "macp-production-monthly"
  budget_type  = "COST"
  limit_amount = tostring(var.monthly_budget_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.budget_notification_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.budget_notification_email]
  }
}

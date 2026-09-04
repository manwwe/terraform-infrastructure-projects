locals {
  tags = {
    Project     = "multi-account-cloud-platform"
    Environment = "security"
    Owner       = var.owner
    ManagedBy   = "Terraform"
  }
}

module "audit_logging" {
  source = "../../modules/audit-logging"

  audit_bucket_name      = var.audit_bucket_name
  access_log_bucket_name = var.access_log_bucket_name
  organization_id        = var.organization_id
  owner                  = var.owner
}

module "account_baseline" {
  source = "../../modules/account-baseline"

  account_alias            = "macp-security"
  config_bucket_name       = module.audit_logging.audit_bucket_name
  config_bucket_key_prefix = "AWSConfig"
  config_kms_key_arn       = module.audit_logging.kms_key_arn
  tags                     = local.tags
}

module "security_services" {
  source = "../../modules/security-services"

  member_accounts        = var.member_accounts
  enrolled_account_names = var.enrolled_account_names
  tags                   = local.tags
}

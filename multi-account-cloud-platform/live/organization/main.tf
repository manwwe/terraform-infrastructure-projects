data "aws_organizations_organization" "current" {}

module "organization" {
  source = "../../modules/organization"

  root_id  = data.aws_organizations_organization.current.roots[0].id
  accounts = var.accounts
}

module "initial_guardrails" {
  count  = var.enable_guardrails ? 1 : 0
  source = "../../modules/service-control-policies"

  allowed_regions = var.allowed_regions

  policy_targets = {
    protect_organization = [
      module.organization.account_ids["development"]
    ]
    protect_audit = [
      module.organization.account_ids["development"]
    ]
    restrict_regions = [
      module.organization.account_ids["development"]
    ]
    protect_s3_public_access = [
      module.organization.account_ids["development"]
    ]
  }
}

resource "aws_guardduty_organization_admin_account" "security" {
  count = var.enable_security_delegated_admin ? 1 : 0

  admin_account_id = module.organization.account_ids["security"]
}

resource "aws_securityhub_organization_admin_account" "security" {
  count = var.enable_security_delegated_admin ? 1 : 0

  admin_account_id = module.organization.account_ids["security"]
}

resource "aws_organizations_delegated_administrator" "config" {
  count = var.enable_security_delegated_admin ? 1 : 0

  account_id        = module.organization.account_ids["security"]
  service_principal = "config-multiaccountsetup.amazonaws.com"
}

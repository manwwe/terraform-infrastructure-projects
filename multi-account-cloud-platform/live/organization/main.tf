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

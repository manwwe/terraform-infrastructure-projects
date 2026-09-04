output "organization_id" {
  description = "ID of the AWS Organization."
  value       = data.aws_organizations_organization.current.id
}

output "organization_root_id" {
  description = "ID of the AWS Organizations root."
  value       = data.aws_organizations_organization.current.roots[0].id
}

output "organizational_unit_ids" {
  description = "Organizational unit IDs keyed by logical name."
  value       = module.organization.organizational_unit_ids
}

output "account_ids" {
  description = "Member account IDs keyed by logical name."
  value       = module.organization.account_ids
}

output "guardrail_policy_ids" {
  description = "Initial guardrail policy IDs, or an empty map when disabled."
  value       = try(module.initial_guardrails[0].policy_ids, {})
}

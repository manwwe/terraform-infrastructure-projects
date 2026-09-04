output "organizational_unit_ids" {
  description = "Organizational unit IDs keyed by logical name."

  value = {
    for name, organizational_unit in aws_organizations_organizational_unit.this :
    name => organizational_unit.id
  }
}

output "account_ids" {
  description = "Member AWS account IDs keyed by logical name."

  value = {
    for name, account in aws_organizations_account.member :
    name => account.id
  }
}

output "account_parent_ids" {
  description = "Parent organizational unit IDs keyed by account name."

  value = {
    for name, account in aws_organizations_account.member :
    name => account.parent_id
  }
}

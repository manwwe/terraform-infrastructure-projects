output "policy_ids" {
  description = "Service control policy IDs keyed by policy name."

  value = {
    for name, policy in aws_organizations_policy.this :
    name => policy.id
  }
}

output "policy_arns" {
  description = "Service control policy ARNs keyed by policy name."

  value = {
    for name, policy in aws_organizations_policy.this :
    name => policy.arn
  }
}

output "attachments" {
  description = "Policy and target IDs keyed by attachment name."

  value = {
    for name, attachment in aws_organizations_policy_attachment.this :
    name => {
      policy_id = attachment.policy_id
      target_id = attachment.target_id
    }
  }
}

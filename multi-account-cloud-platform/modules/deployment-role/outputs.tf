output "plan_role_name" {
  description = "Name of the Terraform plan role."
  value       = aws_iam_role.plan.name
}

output "plan_role_arn" {
  description = "ARN of the Terraform plan role."
  value       = aws_iam_role.plan.arn
}

output "apply_role_name" {
  description = "Name of the Terraform apply role."
  value       = aws_iam_role.apply.name
}

output "apply_role_arn" {
  description = "ARN of the Terraform apply role."
  value       = aws_iam_role.apply.arn
}

output "permissions_boundary_arn" {
  description = "ARN of the permissions boundary attached to both roles."
  value       = aws_iam_policy.deployment_boundary.arn
}

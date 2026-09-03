output "role_name" {
  description = "Name of the application EC2 IAM role."
  value       = aws_iam_role.application.name
}

output "role_arn" {
  description = "ARN of the application EC2 IAM role."
  value       = aws_iam_role.application.arn
}

output "instance_profile_name" {
  description = "Name of the application EC2 instance profile."
  value       = aws_iam_instance_profile.application.name
}

output "instance_profile_arn" {
  description = "ARN of the application EC2 instance profile."
  value       = aws_iam_instance_profile.application.arn
}

output "launch_template_id" {
  description = "ID of the application EC2 launch template."
  value       = aws_launch_template.this.id
}

output "autoscaling_group_name" {
  description = "Name of the application Auto Scaling group."
  value       = aws_autoscaling_group.this.name
}

output "autoscaling_group_arn" {
  description = "ARN of the application Auto Scaling group."
  value       = aws_autoscaling_group.this.arn
}

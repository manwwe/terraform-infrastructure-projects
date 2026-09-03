output "arn" {
  description = "ARN of the application load balancer."
  value       = aws_lb.this.arn
}

output "dns_name" {
  description = "Public DNS name of the application load balancer."
  value       = aws_lb.this.dns_name
}

output "target_group_arn" {
  description = "ARN of the application target group."
  value       = aws_lb_target_group.application.arn
}

output "target_group_name" {
  description = "Name of the application target group."
  value       = aws_lb_target_group.application.name
}

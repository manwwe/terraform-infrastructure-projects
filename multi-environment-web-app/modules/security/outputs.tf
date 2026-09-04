output "load_balancer_security_group_id" {
  description = "ID of the load balancer security group."
  value       = aws_security_group.load_balancer.id
}

output "application_security_group_id" {
  description = "ID of the application security group."
  value       = aws_security_group.application.id
}

output "database_security_group_id" {
  description = "ID of the database security group."
  value       = aws_security_group.database.id
}

output "http_ingress_rule_count" {
  description = "Number of load-balancer HTTP ingress rules."
  value       = length(aws_vpc_security_group_ingress_rule.load_balancer_http)
}

output "https_ingress_rule_count" {
  description = "Number of load-balancer HTTPS ingress rules."
  value       = length(aws_vpc_security_group_ingress_rule.load_balancer_https)
}

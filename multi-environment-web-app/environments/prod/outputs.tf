output "vpc_id" {
  description = "ID of the production VPC."
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the production public subnets."
  value       = module.network.public_subnet_ids
}

output "application_subnet_ids" {
  description = "IDs of the production application subnets."
  value       = module.network.application_subnet_ids
}

output "database_subnet_ids" {
  description = "IDs of the production database subnets."
  value       = module.network.database_subnet_ids
}

output "nat_gateway_public_ips" {
  description = "Production NAT gateway public IPs keyed by Availability Zone."
  value       = module.network.nat_gateway_public_ips
}

output "load_balancer_security_group_id" {
  description = "ID of the production load balancer security group."
  value       = module.security.load_balancer_security_group_id
}

output "application_security_group_id" {
  description = "ID of the production application security group."
  value       = module.security.application_security_group_id
}

output "database_security_group_id" {
  description = "ID of the production database security group."
  value       = module.security.database_security_group_id
}

output "application_iam_role_name" {
  description = "Name of the production application EC2 IAM role."
  value       = module.iam.role_name
}

output "application_iam_role_arn" {
  description = "ARN of the production application EC2 IAM role."
  value       = module.iam.role_arn
}

output "application_instance_profile_name" {
  description = "Name of the production application EC2 instance profile."
  value       = module.iam.instance_profile_name
}

output "application_instance_profile_arn" {
  description = "ARN of the production application EC2 instance profile."
  value       = module.iam.instance_profile_arn
}

output "database_instance_identifier" {
  description = "Identifier of the production PostgreSQL DB instance."
  value       = module.rds.db_instance_identifier
}

output "database_instance_arn" {
  description = "ARN of the production PostgreSQL DB instance."
  value       = module.rds.db_instance_arn
}

output "database_address" {
  description = "DNS address of the production PostgreSQL DB instance."
  value       = module.rds.address
}

output "database_endpoint" {
  description = "Connection endpoint of the production PostgreSQL DB instance."
  value       = module.rds.endpoint
}

output "database_port" {
  description = "Port used by the production PostgreSQL DB instance."
  value       = module.rds.port
}

output "database_name" {
  description = "Name of the initial production PostgreSQL database."
  value       = module.rds.database_name
}

output "database_master_user_secret_arn" {
  description = "ARN of the RDS-managed production master-user secret."
  value       = module.rds.master_user_secret_arn
}

output "application_launch_template_id" {
  description = "ID of the production application launch template."
  value       = module.compute.launch_template_id
}

output "application_autoscaling_group_name" {
  description = "Name of the production application Auto Scaling group."
  value       = module.compute.autoscaling_group_name
}

output "application_autoscaling_group_arn" {
  description = "ARN of the production application Auto Scaling group."
  value       = module.compute.autoscaling_group_arn
}

output "application_load_balancer_arn" {
  description = "ARN of the production application load balancer."
  value       = module.load_balancer.arn
}

output "application_load_balancer_dns_name" {
  description = "Public DNS name of the production application load balancer."
  value       = module.load_balancer.dns_name
}

output "application_target_group_arn" {
  description = "ARN of the production application target group."
  value       = module.load_balancer.target_group_arn
}

output "application_target_group_name" {
  description = "Name of the production application target group."
  value       = module.load_balancer.target_group_name
}

output "cloudwatch_log_group_names" {
  description = "CloudWatch log groups used by production."
  value       = module.observability.log_group_names
}

output "cloudwatch_alarm_names" {
  description = "Essential CloudWatch alarms used by production."
  value       = module.observability.alarm_names
}

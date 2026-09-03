output "vpc_id" {
  description = "ID of the development VPC."
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the development public subnets."
  value       = module.network.public_subnet_ids
}

output "application_subnet_ids" {
  description = "IDs of the development application subnets."
  value       = module.network.application_subnet_ids
}

output "database_subnet_ids" {
  description = "IDs of the development database subnets."
  value       = module.network.database_subnet_ids
}

output "nat_gateway_public_ips" {
  description = "Development NAT gateway public IPs keyed by Availability Zone."
  value       = module.network.nat_gateway_public_ips
}

output "load_balancer_security_group_id" {
  description = "ID of the development load balancer security group."
  value       = module.security.load_balancer_security_group_id
}

output "application_security_group_id" {
  description = "ID of the development application security group."
  value       = module.security.application_security_group_id
}

output "database_security_group_id" {
  description = "ID of the development database security group."
  value       = module.security.database_security_group_id
}

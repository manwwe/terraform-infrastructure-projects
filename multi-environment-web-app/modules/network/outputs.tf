output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets in Availability Zone order."
  value = [
    for az in var.availability_zones : aws_subnet.public[az].id
  ]
}

output "application_subnet_ids" {
  description = "IDs of the private application subnets in Availability Zone order."
  value = [
    for az in var.availability_zones : aws_subnet.application[az].id
  ]
}

output "database_subnet_ids" {
  description = "IDs of the private database subnets in Availability Zone order."
  value = [
    for az in var.availability_zones : aws_subnet.database[az].id
  ]
}

output "database_subnet_ids_by_az" {
  description = "IDs of private database subnets keyed by Availability Zone."
  value = {
    for az in var.availability_zones :
    az => aws_subnet.database[az].id
  }
}

output "nat_gateway_public_ips" {
  description = "NAT gateway public IP addresses keyed by Availability Zone."
  value = {
    for az, eip in aws_eip.nat : az => eip.public_ip
  }
}

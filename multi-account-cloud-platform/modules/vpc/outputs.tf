output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = [for zone in var.availability_zones : aws_subnet.public[zone].id]
}

output "private_subnet_ids" {
  value = [for zone in var.availability_zones : aws_subnet.private[zone].id]
}

output "nat_gateway_ids" {
  value = [for zone in sort(keys(aws_nat_gateway.this)) : aws_nat_gateway.this[zone].id]
}

output "flow_log_id" {
  value = aws_flow_log.this.id
}

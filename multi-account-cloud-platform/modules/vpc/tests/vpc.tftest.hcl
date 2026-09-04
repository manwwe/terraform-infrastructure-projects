mock_provider "aws" {}

run "development_network" {
  command = plan
  variables {
    name               = "macp-development"
    vpc_cidr           = "10.10.0.0/16"
    availability_zones = ["us-east-1a", "us-east-1b"]
    nat_gateway_mode   = "single"
  }

  assert {
    condition     = length(aws_subnet.public) == 2 && length(aws_subnet.private) == 2
    error_message = "Development must have public and private subnets in two Availability Zones."
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 1
    error_message = "Development must use one cost-optimized NAT gateway."
  }

  assert {
    condition     = aws_flow_log.this.traffic_type == "ALL"
    error_message = "The VPC must log accepted and rejected traffic."
  }

  assert {
    condition     = length(aws_default_security_group.this.ingress) == 0 && length(aws_default_security_group.this.egress) == 0
    error_message = "The default security group must allow no traffic."
  }
}

run "production_network" {
  command = plan
  variables {
    name               = "macp-production"
    vpc_cidr           = "10.20.0.0/16"
    availability_zones = ["us-east-1a", "us-east-1b"]
    nat_gateway_mode   = "per_az"
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 2
    error_message = "Production must have one NAT gateway per Availability Zone."
  }
}

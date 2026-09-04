mock_provider "aws" {
  mock_resource "aws_security_group" {
    override_during = plan

    defaults = {
      id = "sg-0123456789abcdef0"
    }
  }
}

variables {
  name_prefix                  = "example-prod"
  vpc_id                       = "vpc-0123456789abcdef0"
  application_port            = 80
  database_port               = 5432
  load_balancer_ingress_cidrs = ["203.0.113.0/24"]
  enable_load_balancer_https  = false
  tags = {
    Environment = "test"
  }
}

run "creates_restricted_http_only_path" {
  command = plan

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.load_balancer_http) == 1
    error_message = "The load balancer must allow HTTP from each approved CIDR."
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.load_balancer_https) == 0
    error_message = "HTTPS ingress must be absent when HTTPS is disabled."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.application_from_load_balancer.referenced_security_group_id == aws_security_group.load_balancer.id
    error_message = "Application ingress must be restricted to the load balancer security group."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.database_from_application.referenced_security_group_id == aws_security_group.application.id
    error_message = "Database ingress must be restricted to the application security group."
  }
}

run "creates_https_rules_when_enabled" {
  command = plan

  variables {
    enable_load_balancer_https = true
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.load_balancer_https) == 1
    error_message = "HTTPS ingress must be created for approved CIDRs when enabled."
  }
}

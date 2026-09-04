mock_provider "aws" {
  mock_data "aws_ssm_parameter" {
    defaults = {
      value = "ami-0123456789abcdef0"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
    }
  }

  mock_resource "aws_eip" {
    override_during = plan

    defaults = {
      public_ip = "198.51.100.10"
    }
  }

  mock_resource "aws_db_instance" {
    override_during = plan

    defaults = {
      arn      = "arn:aws:rds:us-east-1:123456789012:db:example-prod"
      address  = "example-prod.us-east-1.rds.amazonaws.com"
      endpoint = "example-prod.us-east-1.rds.amazonaws.com:5432"
      master_user_secret = [{
        secret_arn = "arn:aws:secretsmanager:us-east-1:123456789012:secret:example-prod"
      }]
    }
  }

  mock_resource "aws_lb_target_group" {
    override_during = plan

    defaults = {
      arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/example-prod/0123456789abcdef"
    }
  }
}

variables {
  owner                       = "platform-team"
  aws_region                  = "us-east-1"
  availability_zones          = ["us-east-1a", "us-east-1b"]
  load_balancer_ingress_cidrs = ["203.0.113.0/24"]
}

run "enforces_production_resilience" {
  command = plan

  assert {
    condition     = length(module.network.nat_gateway_public_ips) == 2
    error_message = "Production must create one NAT gateway per Availability Zone."
  }

  assert {
    condition     = module.rds.multi_az == true
    error_message = "Production RDS must use Multi-AZ."
  }

  assert {
    condition = (
      module.rds.deletion_protection == true &&
      module.rds.skip_final_snapshot == false &&
      module.rds.final_snapshot_identifier == "multi-environment-web-app-prod-postgresql-final" &&
      module.rds.backup_retention_period == 30
    )
    error_message = "Production RDS must enable deletion protection, retain 30 days of backups, and require the approved final snapshot."
  }

  assert {
    condition = (
      module.compute.min_size == 2 &&
      module.compute.desired_capacity == 2 &&
      module.compute.max_size == 4
    )
    error_message = "Production Auto Scaling capacity must be 2/2/4."
  }

  assert {
    condition     = length(module.network.application_subnet_ids) == 2
    error_message = "Production networking must provide an application subnet in both Availability Zones."
  }

  assert {
    condition = (
      module.security.http_ingress_rule_count == 1 &&
      module.security.https_ingress_rule_count == 0
    )
    error_message = "Production must allow approved HTTP CIDRs and must not expose unused HTTPS ingress."
  }
}

run "rejects_public_ingress" {
  command = plan

  variables {
    load_balancer_ingress_cidrs = ["0.0.0.0/0"]
  }

  expect_failures = [var.load_balancer_ingress_cidrs]
}

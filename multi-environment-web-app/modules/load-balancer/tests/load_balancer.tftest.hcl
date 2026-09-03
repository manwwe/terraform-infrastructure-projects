mock_provider "aws" {
  mock_resource "aws_lb_target_group" {
    override_during = plan

    defaults = {
      arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/example-dev-app/0123456789abcdef"
    }
  }
}

variables {
  name_prefix = "example-dev"
  vpc_id      = "vpc-0123456789abcdef0"
  public_subnet_ids = [
    "subnet-0123456789abcdef0",
    "subnet-0fedcba9876543210",
  ]
  security_group_id = "sg-0123456789abcdef0"
  application_port  = 80
  tags = {
    Environment = "test"
  }
}

run "creates_public_application_load_balancer" {
  command = plan

  assert {
    condition     = aws_lb.this.internal == false
    error_message = "The application load balancer must be internet-facing."
  }

  assert {
    condition     = aws_lb.this.load_balancer_type == "application"
    error_message = "The load balancer must use the application type."
  }

  assert {
    condition = toset(aws_lb.this.subnets) == toset([
      "subnet-0123456789abcdef0",
      "subnet-0fedcba9876543210",
    ])
    error_message = "The load balancer must span all supplied public subnets."
  }

  assert {
    condition     = toset(aws_lb.this.security_groups) == toset(["sg-0123456789abcdef0"])
    error_message = "The load balancer must use the supplied security group."
  }

  assert {
    condition     = aws_lb.this.drop_invalid_header_fields == true
    error_message = "The load balancer must drop invalid HTTP header fields."
  }
}

run "forwards_http_to_healthy_instances" {
  command = plan

  assert {
    condition = (
      aws_lb_target_group.application.protocol == "HTTP" &&
      aws_lb_target_group.application.port == 80 &&
      aws_lb_target_group.application.target_type == "instance" &&
      aws_lb_target_group.application.vpc_id == "vpc-0123456789abcdef0"
    )
    error_message = "The target group must route HTTP port 80 to EC2 instances in the supplied VPC."
  }

  assert {
    condition = (
      aws_lb_target_group.application.health_check[0].path == "/health" &&
      aws_lb_target_group.application.health_check[0].matcher == "200" &&
      aws_lb_target_group.application.health_check[0].port == "traffic-port"
    )
    error_message = "The target group must require HTTP 200 from /health on the traffic port."
  }

  assert {
    condition = (
      aws_lb_listener.http.port == 80 &&
      aws_lb_listener.http.protocol == "HTTP" &&
      aws_lb_listener.http.default_action[0].type == "forward" &&
      aws_lb_listener.http.default_action[0].target_group_arn == aws_lb_target_group.application.arn
    )
    error_message = "The port 80 HTTP listener must forward to the application target group."
  }
}

run "rejects_insufficient_public_subnets" {
  command = plan

  variables {
    public_subnet_ids = ["subnet-0123456789abcdef0"]
  }

  expect_failures = [var.public_subnet_ids]
}

run "rejects_invalid_application_port" {
  command = plan

  variables {
    application_port = 70000
  }

  expect_failures = [var.application_port]
}

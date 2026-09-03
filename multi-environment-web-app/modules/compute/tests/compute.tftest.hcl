mock_provider "aws" {
  mock_data "aws_ssm_parameter" {
    defaults = {
      value = "ami-0123456789abcdef0"
    }
  }
}

variables {
  name_prefix                   = "example-dev"
  application_subnet_ids        = ["subnet-0123456789abcdef0", "subnet-0fedcba9876543210"]
  application_security_group_id = "sg-0123456789abcdef0"
  instance_profile_name         = "example-dev-application-profile"
  instance_type                 = "t3.micro"
  min_size                      = 1
  desired_capacity              = 1
  max_size                      = 2
  user_data                     = "#!/bin/bash\necho ready"
  tags = {
    Environment = "test"
  }
}

run "creates_private_hardened_compute" {
  command = plan

  assert {
    condition     = aws_launch_template.this.image_id == "ami-0123456789abcdef0"
    error_message = "The launch template must use the AMI returned by the SSM parameter."
  }

  assert {
    condition     = aws_launch_template.this.metadata_options[0].http_tokens == "required"
    error_message = "The launch template must require IMDSv2 tokens."
  }

  assert {
    condition     = aws_launch_template.this.network_interfaces[0].associate_public_ip_address == "false"
    error_message = "Application instances must not receive public IP addresses."
  }

  assert {
    condition     = aws_launch_template.this.block_device_mappings[0].ebs[0].encrypted == "true"
    error_message = "The root EBS volume must be encrypted."
  }

  assert {
    condition     = aws_launch_template.this.network_interfaces[0].security_groups == toset(["sg-0123456789abcdef0"])
    error_message = "The launch template must attach the application security group."
  }

  assert {
    condition     = aws_launch_template.this.iam_instance_profile[0].name == "example-dev-application-profile"
    error_message = "The launch template must attach the application instance profile."
  }

  assert {
    condition = toset(aws_autoscaling_group.this.vpc_zone_identifier) == toset([
      "subnet-0123456789abcdef0",
      "subnet-0fedcba9876543210",
    ])
    error_message = "The Auto Scaling group must span the supplied private application subnets."
  }

  assert {
    condition = (
      aws_autoscaling_group.this.min_size == 1 &&
      aws_autoscaling_group.this.desired_capacity == 1 &&
      aws_autoscaling_group.this.max_size == 2
    )
    error_message = "The Auto Scaling group must use the supplied capacity values."
  }

  assert {
    condition = (
      aws_autoscaling_group.this.instance_refresh[0].strategy == "Rolling" &&
      aws_autoscaling_group.this.instance_refresh[0].preferences[0].min_healthy_percentage == 100 &&
      aws_autoscaling_group.this.instance_refresh[0].preferences[0].max_healthy_percentage == 200
    )
    error_message = "The Auto Scaling group must replace instances with the approved rolling strategy."
  }

  assert {
    condition     = aws_autoscaling_group.this.health_check_type == "EC2"
    error_message = "The group must use EC2 health checks before a target group is attached."
  }
}

run "uses_elb_health_checks_with_target_group" {
  command = plan

  variables {
    target_group_arns = [
      "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/example/0123456789abcdef"
    ]
  }

  assert {
    condition     = aws_autoscaling_group.this.health_check_type == "ELB"
    error_message = "The group must use ELB health checks when a target group is attached."
  }
}

run "rejects_invalid_capacity_order" {
  command = plan

  variables {
    min_size         = 2
    desired_capacity = 1
    max_size         = 3
  }

  expect_failures = [aws_autoscaling_group.this]
}

run "rejects_oversized_user_data" {
  command = plan

  variables {
    user_data = join("", concat(
      ["#!/bin/bash\n"],
      [for index in range(1024) : "0123456789abcdef"]
    ))
  }

  expect_failures = [var.user_data]
}

run "accepts_user_data_at_exact_limit" {
  command = plan

  variables {
    user_data = join("", [
      "#!/bin/bash\n",
      substr(join("", [for index in range(1024) : "0123456789abcdef"]), 0, 16372),
    ])
  }

  assert {
    condition     = length(var.user_data) == 16384
    error_message = "The exact 16,384-byte ASCII boundary must remain valid."
  }
}

run "rejects_multibyte_user_data" {
  command = plan

  variables {
    user_data = "#!/bin/bash\necho 'é'"
  }

  expect_failures = [var.user_data]
}

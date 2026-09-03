data "aws_ssm_parameter" "amazon_linux_2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

locals {
  instance_tags = merge(var.tags, {
    Name = "${var.name_prefix}-application"
    Tier = "application"
  })
}

resource "aws_launch_template" "this" {
  name_prefix            = "${var.name_prefix}-application-"
  description            = "Launch template for ${var.name_prefix} application instances."
  image_id               = data.aws_ssm_parameter.amazon_linux_2023_ami.value
  instance_type          = var.instance_type
  update_default_version = true
  user_data              = base64encode(var.user_data)

  iam_instance_profile {
    name = var.instance_profile_name
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_protocol_ipv6          = "disabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "required"
    instance_metadata_tags      = "disabled"
  }

  network_interfaces {
    associate_public_ip_address = false
    delete_on_termination       = true
    device_index                = 0
    security_groups             = [var.application_security_group_id]
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      delete_on_termination = true
      encrypted             = true
      volume_size           = 8
      volume_type           = "gp3"
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = local.instance_tags
  }

  tag_specifications {
    resource_type = "volume"
    tags          = local.instance_tags
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-application-launch-template"
  })
}

resource "aws_autoscaling_group" "this" {
  name = "${var.name_prefix}-application-asg"

  min_size         = var.min_size
  desired_capacity = var.desired_capacity
  max_size         = var.max_size

  vpc_zone_identifier = sort(tolist(var.application_subnet_ids))
  target_group_arns   = sort(tolist(var.target_group_arns))

  health_check_type         = length(var.target_group_arns) > 0 ? "ELB" : "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.this.id
    version = aws_launch_template.this.latest_version
  }

  instance_refresh {
    strategy = "Rolling"

    preferences {
      max_healthy_percentage = 200
      min_healthy_percentage = 100
      skip_matching          = true
    }
  }

  dynamic "tag" {
    for_each = local.instance_tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    precondition {
      condition = (
        var.min_size <= var.desired_capacity &&
        var.desired_capacity <= var.max_size
      )
      error_message = "Capacity must satisfy min_size <= desired_capacity <= max_size."
    }
  }
}

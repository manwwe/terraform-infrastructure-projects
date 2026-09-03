locals {
  load_balancer_name = substr("${var.name_prefix}-alb", 0, 32)
  target_group_name  = substr("${var.name_prefix}-app", 0, 32)
}

resource "aws_lb" "this" {
  name                       = local.load_balancer_name
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [var.security_group_id]
  subnets                    = sort(tolist(var.public_subnet_ids))
  drop_invalid_header_fields = true

  tags = merge(var.tags, {
    Name = local.load_balancer_name
  })
}

resource "aws_lb_target_group" "application" {
  name                 = local.target_group_name
  port                 = var.application_port
  protocol             = "HTTP"
  target_type          = "instance"
  vpc_id               = var.vpc_id
  deregistration_delay = 30

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  tags = merge(var.tags, {
    Name = local.target_group_name
  })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.application.arn
  }

  tags = var.tags
}

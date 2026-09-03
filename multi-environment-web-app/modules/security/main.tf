resource "aws_security_group" "load_balancer" {
  name        = "${var.name_prefix}-load-balancer-sg"
  description = "Controls traffic for the public application load balancer."
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name  = "${var.name_prefix}-load-balancer-sg"
    Layer = "load-balancer"
  })
}

resource "aws_security_group" "application" {
  name        = "${var.name_prefix}-application-sg"
  description = "Controls traffic for the private application instances."
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name  = "${var.name_prefix}-application-sg"
    Layer = "application"
  })
}

resource "aws_security_group" "database" {
  name        = "${var.name_prefix}-database-sg"
  description = "Controls traffic for the private database."
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name  = "${var.name_prefix}-database-sg"
    Layer = "database"
  })
}

resource "aws_vpc_security_group_ingress_rule" "load_balancer_http" {
  for_each = var.load_balancer_ingress_cidrs

  security_group_id = aws_security_group.load_balancer.id
  cidr_ipv4         = each.value
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description       = "Allows public HTTP traffic."
}

resource "aws_vpc_security_group_ingress_rule" "load_balancer_https" {
  for_each = var.load_balancer_ingress_cidrs

  security_group_id = aws_security_group.load_balancer.id
  cidr_ipv4         = each.value
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "Allows public HTTPS traffic."
}

resource "aws_vpc_security_group_egress_rule" "load_balancer_to_application" {
  security_group_id            = aws_security_group.load_balancer.id
  referenced_security_group_id = aws_security_group.application.id
  from_port                    = var.application_port
  to_port                      = var.application_port
  ip_protocol                  = "tcp"
  description                  = "Allows traffic to the application instances."
}

resource "aws_vpc_security_group_ingress_rule" "application_from_load_balancer" {
  security_group_id            = aws_security_group.application.id
  referenced_security_group_id = aws_security_group.load_balancer.id
  from_port                    = var.application_port
  to_port                      = var.application_port
  ip_protocol                  = "tcp"
  description                  = "Allows application traffic from the load balancer."
}

resource "aws_vpc_security_group_egress_rule" "application_outbound" {
  security_group_id = aws_security_group.application.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allows outbound traffic for updates and external services."
}

resource "aws_vpc_security_group_ingress_rule" "database_from_application" {
  security_group_id            = aws_security_group.database.id
  referenced_security_group_id = aws_security_group.application.id
  from_port                    = var.database_port
  to_port                      = var.database_port
  ip_protocol                  = "tcp"
  description                  = "Allows database traffic from the application instances."
}

locals {
  association_keys = sort(keys(var.vpc_associations))
  primary_key      = local.association_keys[0]
}

resource "aws_route53_zone" "this" {
  name    = var.zone_name
  comment = "Private parent zone managed by Terraform"

  vpc {
    vpc_id     = var.vpc_associations[local.primary_key].vpc_id
    vpc_region = var.vpc_associations[local.primary_key].vpc_region
  }

  tags = merge(var.tags, {
    Name      = var.zone_name
    ManagedBy = "Terraform"
  })

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route53_zone_association" "this" {
  for_each = {
    for key, association in var.vpc_associations : key => association
    if key != local.primary_key
  }

  zone_id    = aws_route53_zone.this.zone_id
  vpc_id     = each.value.vpc_id
  vpc_region = each.value.vpc_region
}

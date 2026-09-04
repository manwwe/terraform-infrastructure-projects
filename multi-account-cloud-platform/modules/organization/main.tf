locals {
  organizational_units = {
    security       = "Security"
    infrastructure = "Infrastructure"
    workloads      = "Workloads"
  }
}

resource "aws_organizations_organizational_unit" "this" {
  for_each = local.organizational_units

  name      = each.value
  parent_id = var.root_id

  tags = {
    Name      = each.value
    ManagedBy = "Terraform"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_organizations_account" "member" {
  for_each = var.accounts

  name  = each.value.name
  email = each.value.email
  parent_id = aws_organizations_organizational_unit.this[
    each.value.organizational_unit
  ].id

  close_on_deletion = false

  tags = {
    Name      = each.value.name
    ManagedBy = "Terraform"
  }

  lifecycle {
    prevent_destroy = true
  }
}

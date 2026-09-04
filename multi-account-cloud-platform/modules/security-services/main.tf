locals {
  enrolled_accounts = {
    for name, account in var.member_accounts : name => account
    if contains(var.enrolled_account_names, name)
  }
}

resource "aws_iam_role" "config_aggregator" {
  name = "macp-config-aggregator"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "config.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "config_aggregator" {
  role       = aws_iam_role.config_aggregator.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRoleForOrganizations"
}

resource "aws_config_configuration_aggregator" "organization" {
  name = "macp-organization"
  organization_aggregation_source {
    all_regions = true
    role_arn    = aws_iam_role.config_aggregator.arn
  }
  depends_on = [aws_iam_role_policy_attachment.config_aggregator]
  tags       = var.tags
}

resource "aws_guardduty_detector" "this" {
  count  = var.enable_guardduty ? 1 : 0
  enable = true
  tags   = var.tags
}

resource "aws_guardduty_member" "this" {
  for_each    = var.enable_guardduty ? local.enrolled_accounts : {}
  detector_id = aws_guardduty_detector.this[0].id
  account_id  = each.value.account_id
  email       = each.value.email
  invite      = false
}

resource "aws_securityhub_account" "this" {
  count                    = var.enable_security_hub ? 1 : 0
  enable_default_standards = true
}

resource "aws_securityhub_finding_aggregator" "this" {
  count        = var.enable_security_hub ? 1 : 0
  linking_mode = "ALL_REGIONS"
  depends_on   = [aws_securityhub_account.this]
}

resource "aws_securityhub_member" "this" {
  for_each   = var.enable_security_hub ? local.enrolled_accounts : {}
  account_id = each.value.account_id
  email      = each.value.email
  invite     = false
  depends_on = [aws_securityhub_account.this]
}

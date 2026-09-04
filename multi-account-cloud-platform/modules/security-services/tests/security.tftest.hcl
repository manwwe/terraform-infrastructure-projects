mock_provider "aws" {}

run "development_first_enrollment" {
  command = apply
  variables {
    member_accounts = {
      development = { account_id = "111111111111", email = "dev@example.com" }
      production  = { account_id = "222222222222", email = "prod@example.com" }
    }
    enrolled_account_names = ["development"]
  }
  override_resource {
    target = aws_iam_role.config_aggregator
    values = { arn = "arn:aws:iam::333333333333:role/macp-config-aggregator" }
  }
  assert {
    condition     = aws_config_configuration_aggregator.organization.organization_aggregation_source[0].all_regions
    error_message = "Config must aggregate all Regions."
  }
  assert {
    condition     = length(aws_guardduty_member.this) == 1 && contains(keys(aws_guardduty_member.this), "development")
    error_message = "GuardDuty must initially enroll only Development."
  }
  assert {
    condition     = length(aws_securityhub_member.this) == 1 && contains(keys(aws_securityhub_member.this), "development")
    error_message = "Security Hub must initially enroll only Development."
  }
  assert {
    condition     = aws_securityhub_finding_aggregator.this[0].linking_mode == "ALL_REGIONS"
    error_message = "Security Hub findings must aggregate across Regions."
  }
}

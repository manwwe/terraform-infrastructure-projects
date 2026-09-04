mock_provider "aws" {}

run "secure_account_baseline" {
  command = apply
  variables {
    account_alias      = "macp-development"
    config_bucket_name = "macp-security-audit-example"
  }
  override_resource {
    target = aws_iam_role.config
    values = { arn = "arn:aws:iam::111111111111:role/macp-config-recorder" }
  }
  assert {
    condition     = aws_config_configuration_recorder.this.recording_group[0].all_supported
    error_message = "Config must record all supported resources."
  }
  assert {
    condition     = aws_config_configuration_recorder_status.this.is_enabled
    error_message = "The Config recorder must be enabled."
  }
  assert {
    condition     = aws_config_delivery_channel.this.s3_bucket_name == "macp-security-audit-example"
    error_message = "Config must deliver to central audit storage."
  }
  assert {
    condition     = aws_s3_account_public_access_block.this.restrict_public_buckets
    error_message = "Account-level S3 public access must be blocked."
  }
  assert {
    condition     = aws_iam_account_password_policy.this.minimum_password_length >= 14
    error_message = "The IAM password policy must require at least 14 characters."
  }
}

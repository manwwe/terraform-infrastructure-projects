mock_provider "aws" {
  mock_data "aws_caller_identity" { defaults = { account_id = "111111111111" } }
  mock_data "aws_partition" { defaults = { partition = "aws" } }
}

run "central_audit_controls" {
  command = apply
  variables {
    audit_bucket_name      = "macp-security-audit-example"
    access_log_bucket_name = "macp-security-access-example"
    organization_id        = "o-abcdefghij"
    owner                  = "platform-team"
  }

  override_resource {
    target = aws_kms_key.audit
    values = {
      arn = "arn:aws:kms:us-east-1:111111111111:key/11111111-2222-3333-4444-555555555555"
    }
  }

  assert {
    condition     = aws_s3_bucket_versioning.audit.versioning_configuration[0].status == "Enabled"
    error_message = "Audit bucket versioning must be enabled."
  }
  assert {
    condition     = one(aws_s3_bucket_server_side_encryption_configuration.audit.rule).apply_server_side_encryption_by_default[0].sse_algorithm == "aws:kms"
    error_message = "Audit logs must use KMS encryption."
  }
  assert {
    condition     = aws_s3_bucket_public_access_block.audit.restrict_public_buckets
    error_message = "Audit storage must block public access."
  }
  assert {
    condition     = aws_s3_bucket_logging.audit.target_bucket == aws_s3_bucket.access_logs.id
    error_message = "Audit bucket access logging must target the access-log bucket."
  }
  assert {
    condition     = aws_cloudtrail.organization.is_organization_trail && aws_cloudtrail.organization.is_multi_region_trail && aws_cloudtrail.organization.enable_log_file_validation
    error_message = "CloudTrail must cover the organization and all Regions with validation."
  }
  assert {
    condition     = strcontains(aws_s3_bucket_policy.audit.policy, "aws:SecureTransport") && strcontains(aws_s3_bucket_policy.audit.policy, "cloudtrail.amazonaws.com")
    error_message = "The audit policy must require TLS and permit CloudTrail delivery."
  }
  assert {
    condition     = strcontains(aws_s3_bucket_policy.audit.policy, "config.amazonaws.com") && strcontains(aws_s3_bucket_policy.audit.policy, "aws:SourceOrgID")
    error_message = "The audit policy must permit AWS Config delivery from this organization."
  }
  assert {
    condition     = strcontains(aws_s3_bucket_policy.access_logs.policy, "logging.s3.amazonaws.com") && strcontains(aws_s3_bucket_policy.access_logs.policy, "aws:SourceAccount")
    error_message = "The access-log bucket must permit only scoped S3 log delivery."
  }
  assert {
    condition     = length(one(aws_s3_bucket_lifecycle_configuration.audit.rule).transition) == 2
    error_message = "Audit logs must have both archive transitions."
  }
}

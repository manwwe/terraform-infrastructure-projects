mock_provider "aws" {}

run "secure_state_storage" {
  command = apply

  variables {
    bucket_name = "macp-shared-terraform-state-example"
    kms_alias   = "alias/macp-shared-terraform-state"
    owner       = "platform-team"
  }

  assert {
    condition     = aws_s3_bucket_versioning.state.versioning_configuration[0].status == "Enabled"
    error_message = "The state bucket must have versioning enabled."
  }

  assert {
    condition = (
      one(
        aws_s3_bucket_server_side_encryption_configuration.state.rule
      ).apply_server_side_encryption_by_default[0].sse_algorithm == "aws:kms"
    )
    error_message = "The state bucket must use AWS KMS encryption."
  }

  assert {
    condition = (
      aws_s3_bucket_public_access_block.state.block_public_acls &&
      aws_s3_bucket_public_access_block.state.block_public_policy &&
      aws_s3_bucket_public_access_block.state.ignore_public_acls &&
      aws_s3_bucket_public_access_block.state.restrict_public_buckets
    )
    error_message = "Every S3 public-access protection must be enabled."
  }

  assert {
    condition = strcontains(
      aws_s3_bucket_policy.state.policy,
      "aws:SecureTransport"
    )
    error_message = "The bucket policy must deny requests that do not use TLS."
  }

  assert {
    condition     = output.backend_configuration.use_lockfile
    error_message = "The backend configuration must enable S3 native locking."
  }
}

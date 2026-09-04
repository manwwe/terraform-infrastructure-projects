output "bucket_name" {
  description = "Name of the S3 bucket containing Terraform state."
  value       = aws_s3_bucket.state.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket containing Terraform state."
  value       = aws_s3_bucket.state.arn
}

output "kms_key_arn" {
  description = "ARN of the KMS key used to encrypt Terraform state."
  value       = aws_kms_key.state.arn
}

output "backend_configuration" {
  description = "Values required when configuring an S3 Terraform backend."

  value = {
    bucket       = aws_s3_bucket.state.id
    encrypt      = true
    kms_key_id   = aws_kms_key.state.arn
    use_lockfile = true
  }
}

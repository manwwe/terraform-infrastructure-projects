output "audit_bucket_name" { value = aws_s3_bucket.audit.id }
output "access_log_bucket_name" { value = aws_s3_bucket.access_logs.id }
output "kms_key_arn" { value = aws_kms_key.audit.arn }
output "organization_trail_arn" { value = aws_cloudtrail.organization.arn }

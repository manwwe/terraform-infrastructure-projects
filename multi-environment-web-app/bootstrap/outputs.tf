output "state_bucket_name" {
  value       = aws_s3_bucket.terraform_state.id
  description = "Name of the bucket storing Terraform state"
}

output "state_bucket_arn" {
  value       = aws_s3_bucket.terraform_state.arn
  description = "ARN of the bucket storing Terraform state"
}

output "aws_account_id" {
  value       = data.aws_caller_identity.current.account_id
  description = "AWS account that owns the backend"
}

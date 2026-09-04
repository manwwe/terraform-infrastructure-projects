output "state_bucket_name" {
  description = "Name of the shared Terraform state bucket."
  value       = module.terraform_state.bucket_name
}

output "state_bucket_arn" {
  description = "ARN of the shared Terraform state bucket."
  value       = module.terraform_state.bucket_arn
}

output "state_kms_key_arn" {
  description = "ARN of the state encryption KMS key."
  value       = module.terraform_state.kms_key_arn
}

output "backend_configuration" {
  description = "Values required by S3 backend configurations."
  value       = module.terraform_state.backend_configuration
}

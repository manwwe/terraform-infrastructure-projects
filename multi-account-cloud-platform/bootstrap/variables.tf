variable "aws_region" {
  description = "AWS Region where the Terraform state resources are created."
  type        = string
  default     = "us-east-1"
}

variable "expected_account_id" {
  description = "AWS account ID of the shared-services account."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[0-9]{12}$", var.expected_account_id))
    error_message = "expected_account_id must contain exactly 12 digits."
  }
}

variable "bucket_name" {
  description = "Globally unique name of the Terraform state S3 bucket."
  type        = string
  nullable    = false
}

variable "kms_alias" {
  description = "Alias assigned to the Terraform state KMS key."
  type        = string
  default     = "alias/macp-shared-terraform-state"
}

variable "owner" {
  description = "Team responsible for the state infrastructure."
  type        = string
  nullable    = false
}

variable "project_name" {
  description = "Project name used for resource names and tags."
  type        = string
  default     = "multi-account-cloud-platform"
}

variable "authorized_principal_arns" {
  description = "Cross-account deployment roles allowed to use the state backend."
  type        = set(string)
  default     = []
}

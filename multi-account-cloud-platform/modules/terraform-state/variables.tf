variable "bucket_name" {
  description = "Globally unique name of the S3 bucket used for Terraform state."
  type        = string
  nullable    = false

  validation {
    condition = (
      length(var.bucket_name) >= 3 &&
      length(var.bucket_name) <= 63 &&
      can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.bucket_name))
    )
    error_message = "bucket_name must be a valid S3 bucket name containing 3–63 lowercase characters."
  }
}

variable "kms_alias" {
  description = "Alias assigned to the KMS key that encrypts Terraform state."
  type        = string
  nullable    = false

  validation {
    condition     = startswith(var.kms_alias, "alias/")
    error_message = "kms_alias must start with alias/."
  }
}

variable "owner" {
  description = "Team responsible for the Terraform state infrastructure."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.owner)) > 0
    error_message = "owner must not be empty."
  }
}

variable "project_name" {
  description = "Project name used in resource tags."
  type        = string
  default     = "multi-account-cloud-platform"
}

variable "environment" {
  description = "Environment name used in resource tags."
  type        = string
  default     = "shared"
}

variable "authorized_principal_arns" {
  description = "Cross-account IAM roles allowed to read, write, and lock Terraform state."
  type        = set(string)
  default     = []

  validation {
    condition = alltrue([
      for arn in var.authorized_principal_arns :
      can(regex("^arn:(aws|aws-us-gov|aws-cn):iam::[0-9]{12}:role/.+$", arn))
    ])
    error_message = "Every authorized principal must be an IAM role ARN."
  }
}

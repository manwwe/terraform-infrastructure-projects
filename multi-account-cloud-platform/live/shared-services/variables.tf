variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "shared_services_account_id" {
  type = string
  validation {
    condition     = can(regex("^[0-9]{12}$", var.shared_services_account_id))
    error_message = "shared_services_account_id must contain 12 digits."
  }
}

variable "management_account_id" {
  type = string
  validation {
    condition     = can(regex("^[0-9]{12}$", var.management_account_id))
    error_message = "management_account_id must contain 12 digits."
  }
}

variable "state_bucket_name" {
  description = "Existing remote-state bucket; referenced without recreating it."
  type        = string
}

variable "state_kms_key_arn" {
  description = "Existing KMS key used by the remote-state bucket."
  type        = string
}

variable "github_repository" {
  description = "GitHub repository in owner/name form."
  type        = string
  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repository))
    error_message = "github_repository must use owner/name format."
  }
}

variable "owner" {
  type = string
}

variable "private_dns" {
  description = "Optional private parent zone and its initial VPC associations."
  type = object({
    zone_name = string
    vpc_associations = map(object({
      vpc_id     = string
      vpc_region = string
    }))
  })
  default = null
}

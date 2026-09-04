variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "development_account_id" {
  type = string
  validation {
    condition     = can(regex("^[0-9]{12}$", var.development_account_id))
    error_message = "development_account_id must contain 12 digits."
  }
}

variable "management_account_id" {
  type = string
  validation {
    condition     = can(regex("^[0-9]{12}$", var.management_account_id))
    error_message = "management_account_id must contain 12 digits."
  }
}

variable "github_repository" {
  type = string
  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repository))
    error_message = "github_repository must use owner/name format."
  }
}

variable "owner" {
  type = string
}

variable "config_bucket_name" {
  description = "Central AWS Config delivery bucket in the Security account."
  type        = string
}

variable "config_kms_key_arn" {
  description = "KMS key used by the central AWS Config bucket."
  type        = string
  default     = null
}

variable "vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "monthly_budget_usd" {
  description = "Monthly Development cost threshold in USD."
  type        = number
  default     = 25
  validation {
    condition     = var.monthly_budget_usd > 0
    error_message = "monthly_budget_usd must be greater than zero."
  }
}

variable "budget_notification_email" {
  description = "Real email address that receives budget alerts."
  type        = string
  validation {
    condition     = can(regex("^[^@]+@[^@]+\\.[^@]+$", var.budget_notification_email))
    error_message = "budget_notification_email must be a valid email address."
  }
}

variable "private_zone_id" {
  description = "Optional private hosted-zone ID from Shared Services."
  type        = string
  default     = null
}

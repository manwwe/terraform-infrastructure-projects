variable "audit_bucket_name" {
  description = "Globally unique name of the organization audit bucket."
  type        = string
}

variable "access_log_bucket_name" {
  description = "Globally unique name of the S3 access-log bucket."
  type        = string
}

variable "organization_id" {
  description = "AWS Organization ID allowed to deliver logs."
  type        = string
  validation {
    condition     = can(regex("^o-[a-z0-9]{10,32}$", var.organization_id))
    error_message = "organization_id must be a valid AWS Organization ID."
  }
}

variable "trail_name" {
  description = "Name of the organization CloudTrail trail."
  type        = string
  default     = "macp-organization"
}

variable "owner" {
  description = "Team responsible for centralized audit logging."
  type        = string
}

variable "transition_to_standard_ia_days" {
  description = "Days before audit objects transition to STANDARD_IA."
  type        = number
  default     = 30
}

variable "transition_to_glacier_days" {
  description = "Days before audit objects transition to GLACIER."
  type        = number
  default     = 90
}

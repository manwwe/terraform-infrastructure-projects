variable "name_prefix" {
  description = "Prefix used for deployment role and policy names."
  type        = string
  default     = "macp"

  validation {
    condition     = can(regex("^[a-z0-9+=,.@_-]{1,32}$", var.name_prefix))
    error_message = "name_prefix must be 1-32 characters accepted by IAM."
  }
}

variable "trusted_aws_principal_arns" {
  description = "AWS principal ARNs allowed to assume the deployment roles."
  type        = set(string)
  default     = []

  validation {
    condition = alltrue([
      for arn in var.trusted_aws_principal_arns :
      can(regex("^arn:(aws|aws-us-gov|aws-cn):iam::[0-9]{12}:(root|role/.+|user/.+)$", arn))
    ])
    error_message = "Every trusted AWS principal must be a valid IAM root, role, or user ARN."
  }
}

variable "github_oidc_provider_arn" {
  description = "GitHub Actions OIDC provider ARN. Leave null to disable GitHub trust."
  type        = string
  default     = null

  validation {
    condition = (
      var.github_oidc_provider_arn == null ||
      can(regex("^arn:(aws|aws-us-gov|aws-cn):iam::[0-9]{12}:oidc-provider/token.actions.githubusercontent.com$", var.github_oidc_provider_arn))
    )
    error_message = "github_oidc_provider_arn must identify the GitHub Actions OIDC provider."
  }
}

variable "github_subjects" {
  description = "GitHub OIDC subject patterns allowed to assume the deployment roles."
  type        = set(string)
  default     = []

  validation {
    condition = alltrue([
      for subject in var.github_subjects :
      startswith(subject, "repo:")
    ])
    error_message = "Every GitHub subject must start with repo:."
  }
}

variable "external_id" {
  description = "Optional external ID required from trusted AWS principals."
  type        = string
  default     = null

  validation {
    condition = (
      var.external_id == null ||
      length(var.external_id) >= 2
    )
    error_message = "external_id must contain at least two characters when set."
  }
}

variable "require_mfa" {
  description = "Whether trusted AWS principals must use MFA when assuming a role."
  type        = bool
  default     = false
}

variable "max_session_duration" {
  description = "Maximum role session duration in seconds."
  type        = number
  default     = 3600

  validation {
    condition = (
      var.max_session_duration >= 3600 &&
      var.max_session_duration <= 43200
    )
    error_message = "max_session_duration must be between 3600 and 43200 seconds."
  }
}

variable "plan_policy_arns" {
  description = "Managed policy ARNs attached to the plan role."
  type        = set(string)
  default     = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
}

variable "apply_policy_arns" {
  description = "Managed policy ARNs attached to the apply role."
  type        = set(string)
  default     = ["arn:aws:iam::aws:policy/AdministratorAccess"]
}

variable "tags" {
  description = "Additional tags applied to IAM resources."
  type        = map(string)
  default     = {}
}

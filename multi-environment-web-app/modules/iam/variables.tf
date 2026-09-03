variable "name_prefix" {
  type        = string
  description = "Prefix used when naming IAM resources."

  validation {
    condition     = length(trimspace(var.name_prefix)) > 0
    error_message = "name_prefix must not be empty."
  }
}

variable "cloudwatch_log_group_arns" {
  type        = set(string)
  description = "ARNs of CloudWatch log groups writable by the EC2 instances."
  default     = []

  validation {
    condition = alltrue([
      for arn in var.cloudwatch_log_group_arns :
      length(trimspace(arn)) > 0 &&
      can(regex(
        "^arn:[^:]+:logs:[^:]+:[0-9]{12}:log-group:[^:]+$",
        arn
      ))
    ])
    error_message = "cloudwatch_log_group_arns must contain valid CloudWatch Logs log-group ARNs."
  }
}

variable "secret_arns" {
  type        = set(string)
  description = "ARNs of Secrets Manager secrets readable by the EC2 instances."
  default     = []

  validation {
    condition = alltrue([
      for arn in var.secret_arns :
      length(trimspace(arn)) > 0 &&
      can(regex(
        "^arn:[^:]+:secretsmanager:[^:]+:[0-9]{12}:secret:[^:]+$",
        arn
      ))
    ])
    error_message = "secret_arns must contain valid Secrets Manager secret ARNs."
  }
}

variable "tags" {
  type        = map(string)
  description = "Additional tags applied to IAM resources."
  default     = {}
}

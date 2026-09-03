variable "name_prefix" {
  type        = string
  description = "Lowercase prefix used when naming compute resources."

  validation {
    condition = (
      length(var.name_prefix) <= 64 &&
      !strcontains(var.name_prefix, "--") &&
      can(regex("^[a-z]([a-z0-9-]*[a-z0-9])?$", var.name_prefix))
    )
    error_message = "name_prefix must start with a lowercase letter, end with a lowercase letter or number, contain no consecutive hyphens, and contain at most 64 lowercase letters, numbers, or hyphens."
  }
}

variable "application_subnet_ids" {
  type        = set(string)
  description = "Private application subnet IDs used by the Auto Scaling group."

  validation {
    condition = (
      length(var.application_subnet_ids) >= 2 &&
      alltrue([
        for subnet_id in var.application_subnet_ids :
        can(regex("^subnet-[0-9a-f]+$", subnet_id))
      ])
    )
    error_message = "application_subnet_ids must contain at least two valid subnet IDs."
  }
}

variable "application_security_group_id" {
  type        = string
  description = "ID of the security group attached to application instances."

  validation {
    condition     = can(regex("^sg-[0-9a-f]+$", var.application_security_group_id))
    error_message = "application_security_group_id must be a valid security group ID."
  }
}

variable "instance_profile_name" {
  type        = string
  description = "Name of the IAM instance profile attached to application instances."

  validation {
    condition     = length(trimspace(var.instance_profile_name)) > 0
    error_message = "instance_profile_name must not be empty."
  }
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type used by the Auto Scaling group."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*\\.[a-z0-9]+$", var.instance_type))
    error_message = "instance_type must be a valid EC2 instance type such as t3.micro."
  }
}

variable "min_size" {
  type        = number
  description = "Minimum number of instances in the Auto Scaling group."

  validation {
    condition     = var.min_size >= 0 && floor(var.min_size) == var.min_size
    error_message = "min_size must be a non-negative integer."
  }
}

variable "desired_capacity" {
  type        = number
  description = "Desired number of instances in the Auto Scaling group."

  validation {
    condition     = var.desired_capacity >= 0 && floor(var.desired_capacity) == var.desired_capacity
    error_message = "desired_capacity must be a non-negative integer."
  }
}

variable "max_size" {
  type        = number
  description = "Maximum number of instances in the Auto Scaling group."

  validation {
    condition     = var.max_size >= 0 && floor(var.max_size) == var.max_size
    error_message = "max_size must be a non-negative integer."
  }
}

variable "user_data" {
  type        = string
  description = "Plain-text instance bootstrap script. It must not contain secret values."

  validation {
    condition = (
      startswith(trimspace(var.user_data), "#!") &&
      length(regexall("[^\\x00-\\x7F]", var.user_data)) == 0 &&
      length(var.user_data) <= 16384
    )
    error_message = "user_data must begin with a shebang and contain no more than 16,384 bytes of ASCII text."
  }
}

variable "target_group_arns" {
  type        = set(string)
  description = "Load-balancer target group ARNs attached to the Auto Scaling group."
  default     = []

  validation {
    condition = alltrue([
      for arn in var.target_group_arns :
      can(regex("^arn:[^:]+:elasticloadbalancing:[^:]+:[0-9]{12}:targetgroup/.+$", arn))
    ])
    error_message = "target_group_arns must contain valid load-balancer target group ARNs."
  }
}

variable "tags" {
  type        = map(string)
  description = "Additional tags applied to compute resources."
  default     = {}
}

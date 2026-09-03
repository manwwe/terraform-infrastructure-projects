variable "name_prefix" {
  type        = string
  description = "Lowercase prefix used when naming load-balancing resources."

  validation {
    condition = (
      length(var.name_prefix) <= 64 &&
      !strcontains(var.name_prefix, "--") &&
      can(regex("^[a-z]([a-z0-9-]*[a-z0-9])?$", var.name_prefix))
    )
    error_message = "name_prefix must start with a lowercase letter, end with a lowercase letter or number, contain no consecutive hyphens, and contain at most 64 lowercase letters, numbers, or hyphens."
  }
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC containing the load balancer and target group."

  validation {
    condition     = can(regex("^vpc-[0-9a-f]+$", var.vpc_id))
    error_message = "vpc_id must be a valid VPC ID."
  }
}

variable "public_subnet_ids" {
  type        = set(string)
  description = "Public subnet IDs used by the internet-facing load balancer."

  validation {
    condition = (
      length(var.public_subnet_ids) >= 2 &&
      alltrue([
        for subnet_id in var.public_subnet_ids :
        can(regex("^subnet-[0-9a-f]+$", subnet_id))
      ])
    )
    error_message = "public_subnet_ids must contain at least two valid subnet IDs."
  }
}

variable "security_group_id" {
  type        = string
  description = "ID of the security group attached to the load balancer."

  validation {
    condition     = can(regex("^sg-[0-9a-f]+$", var.security_group_id))
    error_message = "security_group_id must be a valid security group ID."
  }
}

variable "application_port" {
  type        = number
  description = "Port used to reach Nginx on application instances."
  default     = 80

  validation {
    condition = (
      var.application_port >= 1 &&
      var.application_port <= 65535 &&
      floor(var.application_port) == var.application_port
    )
    error_message = "application_port must be an integer from 1 through 65535."
  }
}

variable "tags" {
  type        = map(string)
  description = "Additional tags applied to load-balancing resources."
  default     = {}
}

variable "name_prefix" {
  type        = string
  description = "Prefix used when naming security resources."

  validation {
    condition     = length(trimspace(var.name_prefix)) > 0
    error_message = "name_prefix must not be empty."
  }
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC where security groups are created."

  validation {
    condition     = length(trimspace(var.vpc_id)) > 0
    error_message = "vpc_id must not be empty."
  }
}

variable "application_port" {
  type        = number
  description = "TCP port used by the application."
  default     = 80

  validation {
    condition = (
      var.application_port >= 1 &&
      var.application_port <= 65535 &&
      floor(var.application_port) == var.application_port
    )
    error_message = "application_port must be an integer between 1 and 65535."
  }
}

variable "database_port" {
  type        = number
  description = "TCP port used by the database."
  default     = 5432

  validation {
    condition = (
      var.database_port >= 1 &&
      var.database_port <= 65535 &&
      floor(var.database_port) == var.database_port
    )
    error_message = "database_port must be an integer between 1 and 65535."
  }
}

variable "load_balancer_ingress_cidrs" {
  type        = set(string)
  description = "IPv4 CIDR blocks allowed to reach the load balancer."
  default     = ["0.0.0.0/0"]

  validation {
    condition = (
      length(var.load_balancer_ingress_cidrs) > 0 &&
      alltrue([
        for cidr in var.load_balancer_ingress_cidrs :
        can(cidrnetmask(cidr))
      ])
    )
    error_message = "load_balancer_ingress_cidrs must contain at least one valid IPv4 CIDR block."
  }
}

variable "tags" {
  type        = map(string)
  description = "Additional tags applied to all security groups."
  default     = {}
}

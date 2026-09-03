variable "project_name" {
  type        = string
  description = "Project identifier used in resource names and tags."
  default     = "multi-environment-web-app"

  validation {
    condition     = length(trimspace(var.project_name)) > 0
    error_message = "project_name must not be empty."
  }
}

variable "owner" {
  type        = string
  description = "Name or identifier of the person responsible for the infrastructure."

  validation {
    condition     = length(trimspace(var.owner)) > 0
    error_message = "owner must not be empty."
  }
}

variable "aws_region" {
  type        = string
  description = "AWS Region where development resources are created."
  default     = "us-east-1"

  validation {
    condition     = length(trimspace(var.aws_region)) > 0
    error_message = "aws_region must not be empty."
  }
}

variable "availability_zones" {
  type        = list(string)
  description = "Two distinct Availability Zones used by the development environment."

  validation {
    condition = (
      length(var.availability_zones) == 2 &&
      length(distinct(var.availability_zones)) == 2 &&
      alltrue([
        for zone in var.availability_zones :
        length(trimspace(zone)) > 0
      ])
    )
    error_message = "availability_zones must contain exactly two distinct, non-empty values."
  }
}

variable "vpc_cidr" {
  type        = string
  description = "IPv4 /16 CIDR block assigned to the development VPC."
  default     = "10.10.0.0/16"

  validation {
    condition = (
      can(cidrnetmask(var.vpc_cidr)) &&
      can(regex("/16$", var.vpc_cidr))
    )
    error_message = "vpc_cidr must be a valid IPv4 /16 CIDR block."
  }
}

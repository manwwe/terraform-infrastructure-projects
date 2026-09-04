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
  description = "AWS Region where production resources are planned."
  default     = "us-east-1"

  validation {
    condition     = length(trimspace(var.aws_region)) > 0
    error_message = "aws_region must not be empty."
  }
}

variable "availability_zones" {
  type        = list(string)
  description = "Two distinct Availability Zones used by the production environment."

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
  description = "IPv4 /16 CIDR block assigned to the production VPC."
  default     = "10.20.0.0/16"

  validation {
    condition = (
      can(cidrnetmask(var.vpc_cidr)) &&
      can(regex("/16$", var.vpc_cidr))
    )
    error_message = "vpc_cidr must be a valid IPv4 /16 CIDR block."
  }
}

variable "load_balancer_ingress_cidrs" {
  type        = set(string)
  description = "Restricted IPv4 CIDR blocks allowed to reach the production HTTP load balancer."

  validation {
    condition = (
      length(var.load_balancer_ingress_cidrs) > 0 &&
      !contains(var.load_balancer_ingress_cidrs, "0.0.0.0/0") &&
      alltrue([
        for cidr in var.load_balancer_ingress_cidrs :
        can(cidrnetmask(cidr))
      ])
    )
    error_message = "load_balancer_ingress_cidrs must contain valid restricted IPv4 CIDRs and must not include 0.0.0.0/0."
  }
}

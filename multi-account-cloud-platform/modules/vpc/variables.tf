variable "name" {
  description = "Name prefix for network resources."
  type        = string
}

variable "vpc_cidr" {
  description = "IPv4 CIDR assigned to the VPC."
  type        = string
  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR."
  }
}

variable "availability_zones" {
  description = "Exactly two Availability Zones used by this project."
  type        = list(string)
  validation {
    condition     = length(var.availability_zones) == 2 && length(distinct(var.availability_zones)) == 2
    error_message = "availability_zones must contain exactly two unique zones."
  }
}

variable "nat_gateway_mode" {
  description = "NAT layout: none, single for Development, or per_az for Production."
  type        = string
  default     = "single"
  validation {
    condition     = contains(["none", "single", "per_az"], var.nat_gateway_mode)
    error_message = "nat_gateway_mode must be none, single, or per_az."
  }
}

variable "flow_log_retention_days" {
  description = "CloudWatch retention for VPC flow logs."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags applied to network resources."
  type        = map(string)
  default     = {}
}

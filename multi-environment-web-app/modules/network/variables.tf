variable "name_prefix" {
  type        = string
  description = "Prefix used when naming network resources."

  validation {
    condition     = length(trimspace(var.name_prefix)) > 0
    error_message = "name_prefix must not be empty."
  }
}

variable "vpc_cidr" {
  type        = string
  description = "IPv4 CIDR block assigned to the VPC."

  validation {
    condition = (
      can(cidrnetmask(var.vpc_cidr)) &&
      can(regex("/16$", var.vpc_cidr))
    )
    error_message = "vpc_cidr must be a valid Pv4 /16 CIDR block."
  }
}

variable "availability_zones" {
  type        = list(string)
  description = "Two distinct Availability Zones used by the network."

  validation {
    condition = (
      length(var.availability_zones) == 2 &&
      length(distinct(var.availability_zones)) == 2 &&
      alltrue([for zone in var.availability_zones : length(trimspace(zone)) > 0])
    )
    error_message = "availability_zones must contain exactly two distinct, non-empty values."
  }
}

variable "single_nat_gateway" {
  type        = bool
  description = "Whether to create one shared NAT gateway instead of one per Availability Zone."
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Additional tags applied to all network resources."
  default     = {}
}

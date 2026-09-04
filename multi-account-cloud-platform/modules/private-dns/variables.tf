variable "zone_name" {
  description = "Private parent DNS name."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]+[a-z0-9]$", var.zone_name))
    error_message = "zone_name must be a valid lowercase DNS name."
  }
}

variable "vpc_associations" {
  description = "VPCs initially associated with the private hosted zone."
  type = map(object({
    vpc_id     = string
    vpc_region = string
  }))

  validation {
    condition     = length(var.vpc_associations) > 0
    error_message = "At least one VPC association is required for a private hosted zone."
  }
}

variable "tags" {
  description = "Tags applied to the hosted zone."
  type        = map(string)
  default     = {}
}

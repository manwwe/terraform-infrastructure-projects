variable "allowed_regions" {
  description = "AWS Regions in which regional API operations are permitted."
  type        = set(string)
  nullable    = false

  validation {
    condition = (
      length(var.allowed_regions) > 0 &&
      alltrue([
        for region in var.allowed_regions :
        can(regex("^[a-z]{2}(-gov)?-[a-z]+-[0-9]+$", region))
      ])
    )
    error_message = "allowed_regions must contain at least one valid AWS Region."
  }
}

variable "policy_targets" {
  description = "OU or account IDs receiving each service control policy."
  type        = map(set(string))
  nullable    = false

  validation {
    condition = sort(keys(var.policy_targets)) == sort([
      "protect_audit",
      "protect_organization",
      "protect_s3_public_access",
      "restrict_regions"
    ])
    error_message = "policy_targets must configure all four supported policies."
  }

  validation {
    condition = alltrue([
      for targets in values(var.policy_targets) :
      length(targets) > 0
    ])
    error_message = "Every policy must have at least one target."
  }

  validation {
    condition = alltrue(flatten([
      for targets in values(var.policy_targets) : [
        for target in targets :
        can(regex("^(ou-[a-z0-9]{4,32}-[a-z0-9]{8,32}|[0-9]{12})$", target))
      ]
    ]))
    error_message = "Policy targets must be valid organizational unit or account IDs."
  }
}

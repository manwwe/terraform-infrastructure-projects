variable "aws_region" {
  description = "AWS Region used for regional provider operations."
  type        = string
  default     = "us-east-1"
}

variable "management_account_id" {
  description = "AWS Organizations management account ID."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[0-9]{12}$", var.management_account_id))
    error_message = "management_account_id must contain exactly 12 digits."
  }
}

variable "accounts" {
  description = "Member accounts managed by this Terraform root."

  type = map(object({
    name                = string
    email               = string
    organizational_unit = string
  }))

  nullable = false

  validation {
    condition = alltrue([
      for account in values(var.accounts) :
      contains(
        ["security", "infrastructure", "workloads"],
        account.organizational_unit
      )
    ])
    error_message = "Each account must target security, infrastructure, or workloads."
  }

  validation {
    condition = toset(keys(var.accounts)) == toset([
      "development",
      "production",
      "security",
      "shared_services"
    ])
    error_message = "accounts must define development, production, security, and shared_services."
  }

  validation {
    condition = alltrue([
      for account in values(var.accounts) :
      length(trimspace(account.name)) > 0 &&
      can(regex("^[^@[:space:]]+@[^@[:space:]]+\\.[^@[:space:]]+$", account.email))
    ])
    error_message = "Each account must have a name and a valid email address."
  }
}

variable "allowed_regions" {
  description = "AWS Regions permitted by the Region restriction policy."
  type        = set(string)
  default     = ["us-east-1"]

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

variable "enable_guardrails" {
  description = "Whether to attach the initial guardrails to Development."
  type        = bool
  default     = false
}

variable "owner" {
  description = "Team responsible for the organization infrastructure."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.owner)) > 0
    error_message = "owner must not be empty."
  }
}

variable "root_id" {
  description = "ID of the AWS Organizations root that will contain the organizational units."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^r-[a-z0-9]{4,32}$", var.root_id))
    error_message = "root_id must be a valid AWS Organizations root ID."
  }
}

variable "accounts" {
  description = "Existing member accounts and their intended organizational units."

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
    condition = alltrue([
      for account in values(var.accounts) :
      length(trimspace(account.name)) > 0 &&
      can(regex("^[^@[:space:]]+@[^@[:space:]]+\\.[^@[:space:]]+$", account.email))
    ])
    error_message = "Each account must have a name and a valid email address."
  }
}

variable "member_accounts" {
  type = map(object({ account_id = string, email = string }))
}
variable "enrolled_account_names" {
  type    = set(string)
  default = ["development"]
  validation {
    condition     = length(setsubtract(var.enrolled_account_names, toset(keys(var.member_accounts)))) == 0
    error_message = "Every enrolled account name must exist in member_accounts."
  }
}
variable "enable_guardduty" {
  type    = bool
  default = true
}

variable "enable_security_hub" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}

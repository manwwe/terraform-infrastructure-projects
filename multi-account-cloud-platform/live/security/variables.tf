variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "security_account_id" {
  type = string
}

variable "organization_id" {
  type = string
}

variable "audit_bucket_name" {
  type = string
}

variable "access_log_bucket_name" {
  type = string
}

variable "owner" {
  type = string
}
variable "member_accounts" {
  type = map(object({ account_id = string, email = string }))
}
variable "enrolled_account_names" {
  type    = set(string)
  default = ["development"]
}

variable "management_account_id" { type = string }
variable "github_repository" { type = string }
variable "state_bucket_name" { type = string }
variable "state_kms_key_arn" { type = string }

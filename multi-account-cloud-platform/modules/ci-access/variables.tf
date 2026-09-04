variable "name_prefix" { type = string }
variable "github_repository" { type = string }
variable "github_environment" { type = string }
variable "state_bucket_name" { type = string }
variable "state_kms_key_arn" { type = string }
variable "trusted_aws_principal_arns" {
  type    = set(string)
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}

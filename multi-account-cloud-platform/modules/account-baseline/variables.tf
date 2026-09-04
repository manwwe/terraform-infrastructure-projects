variable "account_alias" {
  type = string
}

variable "config_bucket_name" {
  type = string
}

variable "config_bucket_key_prefix" {
  type    = string
  default = "AWSConfig"
}

variable "config_kms_key_arn" {
  type    = string
  default = null
}

variable "include_global_resource_types" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}

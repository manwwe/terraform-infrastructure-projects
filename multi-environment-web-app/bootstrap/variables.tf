variable "project_name" {
  type        = string
  default     = "multi-environment-web-app"
  description = "Project identifier used in resource names and tags."
}

variable "owner" {
  type        = string
  description = "Name or identifier of the person responsible for the infrastructure."
  validation {
    condition     = length(trimspace(var.owner)) > 0
    error_message = "The owner value must not be empty."
  }
}

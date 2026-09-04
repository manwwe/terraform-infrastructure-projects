locals {
  name_prefix = "${var.project_name}-prod"

  common_tags = {
    Project     = var.project_name
    Environment = "prod"
    ManagedBy   = "terraform"
    Repository  = "terraform-infrastructure-projects"
    Owner       = var.owner
  }
}

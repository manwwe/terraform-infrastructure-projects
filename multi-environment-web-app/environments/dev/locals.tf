locals {
  name_prefix = "${var.project_name}-dev"

  common_tags = {
    Project     = var.project_name
    Environment = "dev"
    ManagedBy   = "terraform"
    Repository  = "terraform-infrastructure-projects"
    Owner       = var.owner
  }

  observability_log_group_names = module.observability.log_group_names
}

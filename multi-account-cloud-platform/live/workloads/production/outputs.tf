output "vpc_id" { value = module.vpc.vpc_id }
output "public_subnet_ids" { value = module.vpc.public_subnet_ids }
output "private_subnet_ids" { value = module.vpc.private_subnet_ids }
output "terraform_plan_role_arn" { value = module.deployment_roles.plan_role_arn }
output "terraform_apply_role_arn" { value = module.deployment_roles.apply_role_arn }
output "config_recorder_name" { value = module.account_baseline.config_recorder_name }
output "budget_name" { value = aws_budgets_budget.monthly.name }

output "github_oidc_provider_arn" { value = aws_iam_openid_connect_provider.github.arn }
output "terraform_plan_role_arn" { value = module.deployment_roles.plan_role_arn }
output "terraform_apply_role_arn" { value = module.deployment_roles.apply_role_arn }
output "private_zone_id" { value = try(module.private_dns[0].zone_id, null) }

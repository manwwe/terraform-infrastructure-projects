output "config_recorder_name" { value = aws_config_configuration_recorder.this.name }
output "config_role_arn" { value = aws_iam_role.config.arn }
output "account_alias" { value = aws_iam_account_alias.this.account_alias }

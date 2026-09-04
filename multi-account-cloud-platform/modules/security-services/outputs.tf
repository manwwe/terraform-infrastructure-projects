output "config_aggregator_arn" { value = aws_config_configuration_aggregator.organization.arn }
output "guardduty_detector_id" { value = try(aws_guardduty_detector.this[0].id, null) }
output "enrolled_account_names" { value = sort(keys(local.enrolled_accounts)) }

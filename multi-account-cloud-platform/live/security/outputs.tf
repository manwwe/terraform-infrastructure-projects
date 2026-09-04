output "audit_bucket_name" { value = module.audit_logging.audit_bucket_name }
output "audit_kms_key_arn" { value = module.audit_logging.kms_key_arn }
output "organization_trail_arn" { value = module.audit_logging.organization_trail_arn }
output "config_aggregator_arn" { value = module.security_services.config_aggregator_arn }
output "guardduty_detector_id" { value = module.security_services.guardduty_detector_id }
output "enrolled_account_names" { value = module.security_services.enrolled_account_names }

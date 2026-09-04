output "log_group_names" {
  description = "CloudWatch log-group names keyed by log source."
  value       = { for key, group in aws_cloudwatch_log_group.this : key => group.name }
}

output "log_group_arns" {
  description = "CloudWatch log-group ARNs keyed by log source."
  value       = { for key, group in aws_cloudwatch_log_group.this : key => group.arn }
}

output "alarm_names" {
  description = "Names of the essential CloudWatch alarms."
  value = {
    alb_unhealthy    = aws_cloudwatch_metric_alarm.alb_unhealthy.alarm_name
    asg_capacity     = aws_cloudwatch_metric_alarm.asg_capacity.alarm_name
    ec2_cpu          = aws_cloudwatch_metric_alarm.ec2_cpu.alarm_name
    rds_cpu          = aws_cloudwatch_metric_alarm.rds_cpu.alarm_name
    rds_free_storage = aws_cloudwatch_metric_alarm.rds_free_storage.alarm_name
  }
}

output "configuration" {
  description = "Non-sensitive environment settings applied to CloudWatch resources."
  value = {
    log_retention_in_days          = var.log_retention_in_days
    minimum_healthy_instance_count = var.minimum_healthy_instance_count
    rds_free_storage_threshold     = var.rds_free_storage_threshold
  }
}

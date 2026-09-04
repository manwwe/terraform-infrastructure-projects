mock_provider "aws" {}

variables {
  name_prefix                    = "example-prod"
  load_balancer_arn_suffix       = "app/example-prod/0123456789abcdef"
  target_group_arn_suffix        = "targetgroup/example-prod/0123456789abcdef"
  autoscaling_group_name         = "example-prod-application-asg"
  database_instance_identifier   = "example-prod-postgresql"
  minimum_healthy_instance_count = 2
  log_retention_in_days          = 30
  ec2_cpu_threshold_percent      = 80
  rds_cpu_threshold_percent      = 80
  rds_free_storage_threshold     = 5368709120
  tags = {
    Environment = "test"
  }
}

run "creates_logs_and_essential_alarms" {
  command = plan

  assert {
    condition = toset(keys(aws_cloudwatch_log_group.this)) == toset([
      "application",
      "nginx",
      "cloud_init",
    ])
    error_message = "The module must create the three approved log groups."
  }

  assert {
    condition = alltrue([
      for group in aws_cloudwatch_log_group.this : group.retention_in_days == 30
    ])
    error_message = "Every log group must use the configured retention."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.alb_unhealthy.namespace == "AWS/ApplicationELB" &&
      aws_cloudwatch_metric_alarm.alb_unhealthy.metric_name == "UnHealthyHostCount" &&
      aws_cloudwatch_metric_alarm.alb_unhealthy.dimensions.LoadBalancer == "app/example-prod/0123456789abcdef" &&
      aws_cloudwatch_metric_alarm.alb_unhealthy.dimensions.TargetGroup == "targetgroup/example-prod/0123456789abcdef" &&
      aws_cloudwatch_metric_alarm.alb_unhealthy.treat_missing_data == "breaching" &&
      aws_cloudwatch_metric_alarm.alb_unhealthy.actions_enabled == false &&
      aws_cloudwatch_metric_alarm.alb_unhealthy.alarm_actions == null
    )
    error_message = "The ALB alarm must monitor unhealthy targets without actions."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.asg_capacity.namespace == "AWS/AutoScaling" &&
      aws_cloudwatch_metric_alarm.asg_capacity.metric_name == "GroupInServiceInstances" &&
      aws_cloudwatch_metric_alarm.asg_capacity.threshold == 2 &&
      aws_cloudwatch_metric_alarm.asg_capacity.dimensions.AutoScalingGroupName == "example-prod-application-asg" &&
      aws_cloudwatch_metric_alarm.asg_capacity.treat_missing_data == "breaching"
    )
    error_message = "The capacity alarm must enforce the environment minimum."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.ec2_cpu.namespace == "AWS/EC2" &&
      aws_cloudwatch_metric_alarm.ec2_cpu.metric_name == "CPUUtilization" &&
      aws_cloudwatch_metric_alarm.ec2_cpu.threshold == 80 &&
      aws_cloudwatch_metric_alarm.ec2_cpu.dimensions.AutoScalingGroupName == "example-prod-application-asg" &&
      aws_cloudwatch_metric_alarm.ec2_cpu.treat_missing_data == "missing"
    )
    error_message = "The EC2 CPU alarm must aggregate the Auto Scaling group."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.rds_cpu.namespace == "AWS/RDS" &&
      aws_cloudwatch_metric_alarm.rds_cpu.metric_name == "CPUUtilization" &&
      aws_cloudwatch_metric_alarm.rds_cpu.threshold == 80 &&
      aws_cloudwatch_metric_alarm.rds_cpu.dimensions.DBInstanceIdentifier == "example-prod-postgresql" &&
      aws_cloudwatch_metric_alarm.rds_cpu.treat_missing_data == "missing"
    )
    error_message = "The RDS CPU alarm must use the configured database identifier."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.rds_free_storage.namespace == "AWS/RDS" &&
      aws_cloudwatch_metric_alarm.rds_free_storage.metric_name == "FreeStorageSpace" &&
      aws_cloudwatch_metric_alarm.rds_free_storage.threshold == 5368709120 &&
      aws_cloudwatch_metric_alarm.rds_free_storage.dimensions.DBInstanceIdentifier == "example-prod-postgresql" &&
      aws_cloudwatch_metric_alarm.rds_free_storage.treat_missing_data == "breaching"
    )
    error_message = "The RDS storage alarm must use the configured byte threshold."
  }
}

run "rejects_invalid_thresholds" {
  command = plan

  variables {
    ec2_cpu_threshold_percent  = 0
    rds_cpu_threshold_percent  = 101
    rds_free_storage_threshold = -1
  }

  expect_failures = [
    var.ec2_cpu_threshold_percent,
    var.rds_cpu_threshold_percent,
    var.rds_free_storage_threshold,
  ]
}

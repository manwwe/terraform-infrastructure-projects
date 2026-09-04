variable "name_prefix" {
  type        = string
  description = "Prefix used for CloudWatch log groups and alarms."

  validation {
    condition     = length(trimspace(var.name_prefix)) > 0
    error_message = "name_prefix must not be empty."
  }
}

variable "load_balancer_arn_suffix" {
  type        = string
  description = "Application Load Balancer ARN suffix used by CloudWatch dimensions."

  validation {
    condition     = startswith(var.load_balancer_arn_suffix, "app/")
    error_message = "load_balancer_arn_suffix must begin with app/."
  }
}

variable "target_group_arn_suffix" {
  type        = string
  description = "Target group ARN suffix used by CloudWatch dimensions."

  validation {
    condition     = startswith(var.target_group_arn_suffix, "targetgroup/")
    error_message = "target_group_arn_suffix must begin with targetgroup/."
  }
}

variable "autoscaling_group_name" {
  type        = string
  description = "Auto Scaling group name used by CloudWatch dimensions."

  validation {
    condition     = length(trimspace(var.autoscaling_group_name)) > 0
    error_message = "autoscaling_group_name must not be empty."
  }
}

variable "database_instance_identifier" {
  type        = string
  description = "RDS DB instance identifier used by CloudWatch dimensions."

  validation {
    condition     = length(trimspace(var.database_instance_identifier)) > 0
    error_message = "database_instance_identifier must not be empty."
  }
}

variable "minimum_healthy_instance_count" {
  type        = number
  description = "Minimum in-service application instance count."

  validation {
    condition = (
      var.minimum_healthy_instance_count > 0 &&
      floor(var.minimum_healthy_instance_count) == var.minimum_healthy_instance_count
    )
    error_message = "minimum_healthy_instance_count must be a positive integer."
  }
}

variable "log_retention_in_days" {
  type        = number
  description = "Number of days that application and instance logs are retained."

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180,
      365, 400, 545, 731, 1096, 1827, 2192, 2557,
      2922, 3288, 3653,
    ], var.log_retention_in_days)
    error_message = "log_retention_in_days must be supported by CloudWatch Logs."
  }
}

variable "ec2_cpu_threshold_percent" {
  type        = number
  description = "EC2 average CPU percentage that triggers an alarm."

  validation {
    condition     = var.ec2_cpu_threshold_percent > 0 && var.ec2_cpu_threshold_percent <= 100
    error_message = "ec2_cpu_threshold_percent must be greater than 0 and no more than 100."
  }
}

variable "rds_cpu_threshold_percent" {
  type        = number
  description = "RDS average CPU percentage that triggers an alarm."

  validation {
    condition     = var.rds_cpu_threshold_percent > 0 && var.rds_cpu_threshold_percent <= 100
    error_message = "rds_cpu_threshold_percent must be greater than 0 and no more than 100."
  }
}

variable "rds_free_storage_threshold" {
  type        = number
  description = "Free RDS storage in bytes below which an alarm triggers."

  validation {
    condition = (
      var.rds_free_storage_threshold > 0 &&
      floor(var.rds_free_storage_threshold) == var.rds_free_storage_threshold
    )
    error_message = "rds_free_storage_threshold must be a positive integer number of bytes."
  }
}

variable "tags" {
  type        = map(string)
  description = "Additional tags applied to CloudWatch resources."
  default     = {}
}

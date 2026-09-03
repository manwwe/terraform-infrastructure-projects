variable "name_prefix" {
  type        = string
  description = "Lowercase prefix used when naming RDS resources."

  validation {
    condition = (
      length(var.name_prefix) <= 52 &&
      !strcontains(var.name_prefix, "--") &&
      can(regex(
        "^[a-z]([a-z0-9-]*[a-z0-9])?$",
        var.name_prefix
      ))
    )
    error_message = "name_prefix must start with a lowercase letter, end with a lowercase letter or number, contain no consecutive hyphens, and contain at most 52 lowercase letters, numbers, or hyphens."
  }
}

variable "database_subnet_ids_by_az" {
  type        = map(string)
  description = "Private database subnet IDs keyed by Availability Zone."

  validation {
    condition = (
      length(var.database_subnet_ids_by_az) >= 2 &&
      alltrue([
        for availability_zone, subnet_id in var.database_subnet_ids_by_az :
        length(trimspace(availability_zone)) > 0 &&
        can(regex("^subnet-[0-9a-f]+$", subnet_id))
      ])
    )
    error_message = "database_subnet_ids_by_az must contain valid subnet IDs for at least two non-empty Availability Zone keys."
  }
}

variable "database_security_group_id" {
  type        = string
  description = "ID of the security group attached to the database instance."

  validation {
    condition     = can(regex("^sg-[0-9a-f]+$", var.database_security_group_id))
    error_message = "database_security_group_id must be a valid security group ID."
  }
}

variable "database_name" {
  type        = string
  description = "Name of the initial PostgreSQL database."

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_]{0,62}$", var.database_name))
    error_message = "database_name must begin with a letter and contain at most 63 letters, numbers, or underscores."
  }
}

variable "master_username" {
  type        = string
  description = "Username for the PostgreSQL master user."

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_]{0,15}$", var.master_username))
    error_message = "master_username must begin with a letter and contain at most 16 letters, numbers, or underscores."
  }
}

variable "engine_version" {
  type        = string
  description = "PostgreSQL engine version used by the database instance."

  validation {
    condition     = can(regex("^[0-9]+(\\.[0-9]+)*$", var.engine_version))
    error_message = "engine_version must be a numeric major or major.minor version."
  }
}

variable "instance_class" {
  type        = string
  description = "RDS instance class used by the database."

  validation {
    condition     = can(regex("^db\\.[A-Za-z0-9]+\\.[A-Za-z0-9]+$", var.instance_class))
    error_message = "instance_class must be a valid RDS instance class such as db.t4g.micro."
  }
}

variable "allocated_storage" {
  type        = number
  description = "Storage allocated to the database in GiB."

  validation {
    condition = (
      var.allocated_storage >= 20 &&
      var.allocated_storage <= 65536 &&
      floor(var.allocated_storage) == var.allocated_storage
    )
    error_message = "allocated_storage must be an integer between 20 and 65536 GiB."
  }
}

variable "storage_type" {
  type        = string
  description = "General-purpose storage type used by the database."

  validation {
    condition     = contains(["gp2", "gp3"], var.storage_type)
    error_message = "storage_type must be either gp2 or gp3."
  }
}

variable "multi_az" {
  type        = bool
  description = "Whether the database uses a Multi-AZ deployment."
}

variable "backup_retention_period" {
  type        = number
  description = "Number of days that automated database backups are retained."

  validation {
    condition = (
      var.backup_retention_period >= 0 &&
      var.backup_retention_period <= 35 &&
      floor(var.backup_retention_period) == var.backup_retention_period
    )
    error_message = "backup_retention_period must be an integer between 0 and 35."
  }
}

variable "deletion_protection" {
  type        = bool
  description = "Whether deletion protection is enabled for the database."
}

variable "skip_final_snapshot" {
  type        = bool
  description = "Whether Terraform skips the final snapshot when destroying the database."
}

variable "final_snapshot_identifier" {
  type        = string
  description = "Identifier of the final snapshot created when final snapshots are enabled."
  default     = null
  nullable    = true

  validation {
    condition = var.final_snapshot_identifier == null ? true : (
      length(var.final_snapshot_identifier) <= 255 &&
      !strcontains(var.final_snapshot_identifier, "--") &&
      can(regex(
        "^[A-Za-z]([A-Za-z0-9-]*[A-Za-z0-9])?$",
        var.final_snapshot_identifier
      ))
    )
    error_message = "final_snapshot_identifier must begin with a letter, end with a letter or number, contain no consecutive hyphens, and contain at most 255 letters, numbers, or hyphens."
  }
}

variable "auto_minor_version_upgrade" {
  type        = bool
  description = "Whether minor engine upgrades are applied automatically."
}

variable "enabled_cloudwatch_logs_exports" {
  type        = set(string)
  description = "PostgreSQL log types exported to CloudWatch Logs."
  default     = []

  validation {
    condition = alltrue([
      for log_type in var.enabled_cloudwatch_logs_exports :
      contains(["postgresql", "upgrade"], log_type)
    ])
    error_message = "enabled_cloudwatch_logs_exports may contain only postgresql or upgrade."
  }
}

variable "cloudwatch_log_retention_in_days" {
  type        = number
  description = "Number of days that exported database logs are retained."

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180,
      365, 400, 545, 731, 1096, 1827, 2192, 2557,
      2922, 3288, 3653,
    ], var.cloudwatch_log_retention_in_days)
    error_message = "cloudwatch_log_retention_in_days must be a retention period supported by CloudWatch Logs."
  }
}

variable "tags" {
  type        = map(string)
  description = "Additional tags applied to RDS resources."
  default     = {}
}

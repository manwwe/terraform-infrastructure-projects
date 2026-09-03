resource "aws_db_subnet_group" "this" {
  name        = "${var.name_prefix}-database-subnet-group"
  description = "Private subnets used by the application database."
  subnet_ids  = sort(values(var.database_subnet_ids_by_az))

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-database-subnet-group"
    Tier = "database"
  })
}

resource "aws_cloudwatch_log_group" "database" {
  for_each = var.enabled_cloudwatch_logs_exports

  name              = "/aws/rds/instance/${var.name_prefix}-postgresql/${each.value}"
  retention_in_days = var.cloudwatch_log_retention_in_days

  tags = merge(var.tags, {
    Name = "/aws/rds/instance/${var.name_prefix}-postgresql/${each.value}"
    Tier = "database"
  })
}

resource "aws_db_instance" "this" {
  depends_on = [aws_cloudwatch_log_group.database]
  identifier = "${var.name_prefix}-postgresql"

  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage = var.allocated_storage
  storage_type      = var.storage_type
  storage_encrypted = true

  db_name                     = var.database_name
  username                    = var.master_username
  manage_master_user_password = true
  port                        = 5432

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.database_security_group_id]
  publicly_accessible    = false
  multi_az               = var.multi_az

  backup_retention_period = var.backup_retention_period
  deletion_protection     = var.deletion_protection
  skip_final_snapshot     = var.skip_final_snapshot
  final_snapshot_identifier = (
    var.skip_final_snapshot ? null : var.final_snapshot_identifier
  )

  auto_minor_version_upgrade      = var.auto_minor_version_upgrade
  enabled_cloudwatch_logs_exports = sort(tolist(var.enabled_cloudwatch_logs_exports))
  performance_insights_enabled    = false
  monitoring_interval             = 0
  copy_tags_to_snapshot           = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-postgresql"
    Tier = "database"
  })

  lifecycle {
    precondition {
      condition = (
        var.skip_final_snapshot ||
        var.final_snapshot_identifier != null
      )
      error_message = "final_snapshot_identifier must be provided when skip_final_snapshot is false."
    }
  }
}

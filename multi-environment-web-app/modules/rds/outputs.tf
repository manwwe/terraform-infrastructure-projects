output "db_instance_identifier" {
  description = "Identifier of the PostgreSQL DB instance."
  value       = aws_db_instance.this.identifier
}

output "db_instance_arn" {
  description = "ARN of the PostgreSQL DB instance."
  value       = aws_db_instance.this.arn
}

output "address" {
  description = "DNS address of the PostgreSQL DB instance."
  value       = aws_db_instance.this.address
}

output "endpoint" {
  description = "Connection endpoint of the PostgreSQL DB instance."
  value       = aws_db_instance.this.endpoint
}

output "port" {
  description = "Port used by the PostgreSQL DB instance."
  value       = aws_db_instance.this.port
}

output "database_name" {
  description = "Name of the initial PostgreSQL database."
  value       = aws_db_instance.this.db_name
}

output "master_user_secret_arn" {
  description = "ARN of the RDS-managed master-user secret."
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}

output "multi_az" {
  description = "Whether the DB instance uses Multi-AZ deployment."
  value       = aws_db_instance.this.multi_az
}

output "deletion_protection" {
  description = "Whether deletion protection is enabled for the DB instance."
  value       = aws_db_instance.this.deletion_protection
}

output "skip_final_snapshot" {
  description = "Whether the DB instance skips a final snapshot during destruction."
  value       = aws_db_instance.this.skip_final_snapshot
}

output "final_snapshot_identifier" {
  description = "Identifier used for the DB instance final snapshot."
  value       = aws_db_instance.this.final_snapshot_identifier
}

output "backup_retention_period" {
  description = "Automated backup retention period for the DB instance."
  value       = aws_db_instance.this.backup_retention_period
}

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

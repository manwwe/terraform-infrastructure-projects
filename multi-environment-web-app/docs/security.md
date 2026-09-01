# Security

## Network Boundaries

The infrastructure will use separate security groups for the load balancer, application, and database layers:

1. The load balancer accepts HTTPS traffic from the internet.
2. EC2 instances accept application traffic only from the load balancer.
3. Amazon RDS accepts PostgreSQL traffic only from the application instances.

Application and database resources will run in private subnets. EC2 instances will not have public IP addresses, and the database subnets will not have internet routes.

## Identity and Access Management

EC2 instances will use an IAM role with only the permissions needed to:

- Register with AWS Systems Manager
- Publish logs and metrics to Amazon CloudWatch
- Retrieve the required application secrets

Terraform operators and automation will use environment-specific IAM permissions. Production access will be more restrictive than development access.

## Secrets

Database credentials will be stored in AWS Secrets Manager. Credentials and other sensitive values must not be committed to the repository or stored in plaintext variable files.

## Encryption

- Terraform state will be encrypted in Amazon S3.
- Amazon RDS storage and backups will be encrypted.
- Secrets Manager will encrypt stored secrets.
- HTTPS will protect client traffic to the load balancer.

## Administrative Access

AWS Systems Manager Session Manager will replace direct SSH access. No inbound SSH rule will be exposed to the internet.

## Production Safeguards

Production will enable deletion protection, stronger backup retention, Multi-AZ database deployment, restricted state access, and additional monitoring and alarms.

# Security

## Implemented Controls

- Only the Application Load Balancer accepts public application traffic.
- EC2 instances and RDS have no public addresses.
- Security-group references enforce ALB → application → database traffic.
- EC2 requires IMDSv2 and uses encrypted EBS storage.
- RDS storage and remote Terraform state are encrypted.
- Systems Manager replaces public SSH access.
- The instance role can read only the configured RDS-managed secret.
- Public access to the state bucket is blocked, and state changes use native S3
  lock files.

## Network Boundaries

The load balancer accepts TCP port 80 from the internet. Its security group can
send application traffic only to the EC2 security group on port 80. The EC2 group
can reach RDS on port 5432, and RDS accepts that traffic only from the EC2 group.
Database subnets have no internet route.

## Secrets

RDS generates and stores its master credential in Secrets Manager. Instance user
data contains the secret ARN and database connection metadata, not the password.
The Flask process retrieves the value at runtime through its IAM role.

Local `terraform.tfvars` and `backend.hcl` files are ignored because they contain
environment-specific configuration. Credentials and secret values must never be
added to examples, logs, documentation, or Git history.

## Administrative Access

Systems Manager Session Manager provides shell access to private instances. No
SSH key pair or inbound port 22 rule is configured. Operators should inspect
application health and service logs without printing Secrets Manager values.

## Current Limitations

Client traffic uses unencrypted HTTP. HTTPS and DNS are outside the current scope.
The application uses the RDS master credential; a future change should use a
restricted application user. CloudWatch application/system log shipping and
alarms are not configured.

## Production Safeguards

Production planning requires explicit ingress CIDRs and rejects `0.0.0.0/0`.
Only those CIDRs can reach HTTP port 80; unused HTTPS ingress is disabled. EC2 and
RDS remain private, and the existing security-group reference chain is reused.
RDS uses Multi-AZ, deletion protection, required final snapshots, encrypted
storage, managed credentials, and 30-day backups. The production configuration
has not been applied.

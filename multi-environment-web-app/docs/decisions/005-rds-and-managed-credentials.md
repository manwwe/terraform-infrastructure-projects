# ADR 005: RDS and Managed Database Credentials

## Status

Accepted

## Context

The application requires a private PostgreSQL database with credentials stored in AWS Secrets Manager. The infrastructure must avoid placing the database password in Terraform configuration or state while remaining reusable across development and production.

Development needs lower-cost lifecycle settings, while production will require stronger availability and deletion safeguards.

## Decision

Create a reusable `rds` module that owns:

- An RDS DB subnet group
- A PostgreSQL DB instance
- RDS-managed master credentials
- PostgreSQL log export to CloudWatch

The module will accept:

- A resource name prefix
- Database subnet IDs
- A database security-group ID
- Database and master-user names
- PostgreSQL engine version
- Instance class
- Allocated storage and storage type
- Multi-AZ configuration
- Backup-retention period
- Deletion-protection setting
- Final-snapshot settings
- Automatic minor-version upgrade setting
- Enabled CloudWatch log exports
- Common resource tags

The module will output:

- The DB instance identifier and ARN
- The database address, endpoint, and port
- The database name
- The RDS-managed master-user secret ARN

The database will always use encrypted storage and will never be publicly accessible. Environments cannot disable these safeguards.

RDS will generate and manage the master-user password through AWS Secrets Manager. Terraform will not create a random password or an `aws_secretsmanager_secret_version` resource. No plaintext password will be accepted as an input or exposed as an output.

The development environment will use:

- PostgreSQL 17
- Database name `appdb`
- Master username `app_admin`
- Instance class `db.t4g.micro`
- 20 GiB of `gp3` storage
- Single-AZ deployment
- One day of backup retention
- Deletion protection disabled
- Final snapshot skipped
- Automatic minor-version upgrades enabled
- PostgreSQL log export to CloudWatch
- Enhanced Monitoring and Performance Insights disabled

The RDS-managed secret ARN will be passed to the IAM module. This will cause the IAM module to create and attach its conditional least-privilege Secrets Manager policy.

If final snapshots are enabled, the module will require a non-empty final-snapshot identifier.

## Alternatives Considered

### Terraform-generated password

Terraform could generate a password and store it with `aws_secretsmanager_secret_version`. This was rejected because the plaintext password would remain in Terraform state even when marked sensitive.

### Manually managed secret

A secret could be created outside Terraform and passed into the configuration. This was rejected because it introduces a manual prerequisite and reduces reproducibility.

### Separate database and subnet-group modules

The DB subnet group could be managed independently. This was rejected because it would unnecessarily split one database infrastructure boundary.

### Database resources in each environment root

Each environment could define its own RDS resources directly. This was rejected because it would duplicate logic and weaken consistency between development and production.

## Consequences

- Database password plaintext does not enter Terraform configuration or state.
- RDS owns the master-password lifecycle.
- The application role receives access only to the managed database secret.
- Development and production can use different capacity and lifecycle settings through module inputs.
- The RDS module must be applied before its managed secret can be inspected.
- Customer-managed KMS keys, Enhanced Monitoring, and Performance Insights remain future enhancements.

## Verification

The implementation will be verified by:

- Running Terraform formatting and validation
- Reviewing the development execution plan
- Applying the development infrastructure
- Confirming that the database is private and encrypted
- Confirming that RDS created the managed secret
- Confirming that the application IAM role can read only that secret
- Running a no-drift plan
- Destroying the development infrastructure
- Confirming that the Terraform state is empty

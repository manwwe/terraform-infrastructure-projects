# ADR 004: EC2 IAM and Systems Manager Access

## Status

Accepted

## Context

EC2 application instances need private administrative access through AWS Systems Manager. They will also need permission to publish logs to specific CloudWatch log groups and retrieve specific application secrets from AWS Secrets Manager.

These permissions must remain reusable across environments and must not grant broad access to unrelated AWS resources.

## Decision

Create a dedicated reusable IAM module for the application instances.

The module will own:

- An IAM role trusted only by the EC2 service
- An attachment for the AWS-managed `AmazonSSMManagedInstanceCore` policy
- A custom CloudWatch Logs policy and attachment
- A custom Secrets Manager policy and attachment
- An EC2 instance profile

The module will accept:

- A resource name prefix
- A set of CloudWatch log-group ARNs
- A set of Secrets Manager secret ARNs
- Common resource tags

The module will output:

- The IAM role name and ARN
- The instance profile name and ARN

The CloudWatch policy will allow:

- `logs:CreateLogStream`
- `logs:DescribeLogStreams`
- `logs:PutLogEvents`

These actions will apply only to log streams beneath the supplied log groups. The policy will not permit `logs:CreateLogGroup` because Terraform will manage the log groups.

The Secrets Manager policy will allow:

- `secretsmanager:GetSecretValue`
- `secretsmanager:DescribeSecret`

These actions will apply only to the supplied secret ARNs.

The CloudWatch and Secrets Manager policies will be created and attached only when their corresponding ARN sets are non-empty. This allows the instance role and Systems Manager access to be introduced before log groups and secrets exist.

Customer-managed KMS key permissions will not be included yet. They will be added if a future secret requires access to a customer-managed key.

## Alternatives Considered

### Separate IAM modules for each capability

Separate modules could manage the role, Systems Manager access, logging permissions, and secret permissions independently. This would provide additional composability but would unnecessarily fragment one EC2 identity boundary.

### IAM resources inside the compute module

The future compute module could own the role and instance profile. This would simplify some wiring but would couple instance permissions to the EC2 implementation and make the IAM configuration harder to test and reuse independently.

### Wildcard resource permissions

Wildcard permissions would allow the policies to exist before log groups and secrets are created. This approach was rejected because it would grant access to unrelated resources and violate the project’s least-privilege goal.

## Consequences

- EC2 instances can be administered without public IP addresses or inbound SSH access.
- Logging and secret permissions remain limited to explicitly supplied resources.
- IAM configuration can be developed and tested independently of compute resources.
- The future compute module only needs the instance profile name.
- Additional permissions must be added explicitly when new instance capabilities are introduced.

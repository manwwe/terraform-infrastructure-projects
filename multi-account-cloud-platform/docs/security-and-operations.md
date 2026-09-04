# Security and Operations

## Access Model

Human users authenticate with IAM Identity Center and receive time-limited
sessions. Routine work uses platform-engineer or read-only permission sets.
Administrative access is limited, logged, and separated from the break-glass
path. CI authenticates through GitHub OIDC and receives no stored AWS access key.

## Preventative Controls

- Restrict AWS Regions while allowing required global services.
- Protect organization membership and central logging configuration.
- Preserve account-level S3 public-access protection.
- Require encryption and TLS for Terraform state and audit storage.
- Use permissions boundaries for deployment roles.
- Keep SCP rollout scoped to Development until behavior is verified.

## Detective Controls

- Organization CloudTrail management events delivered to Security
- AWS Config recording in every member account
- Central AWS Config aggregation
- GuardDuty and Security Hub aggregation where supported
- VPC Flow Logs for workload networks
- Alerts for root-user activity, break-glass role use, CloudTrail changes, and
  high-severity security findings

## Operational Ownership

| Area | Primary owner | Evidence |
|---|---|---|
| Organization and policies | Platform administrator | Terraform plans and CloudTrail |
| Identity and access | Platform administrator | Identity Center assignments and access reviews |
| Audit storage | Security owner | S3 inventory, KMS logs, CloudTrail delivery status |
| Security findings | Security owner | Security Hub and GuardDuty findings |
| Shared state and CI trust | Platform engineer | State access logs and OIDC role sessions |
| Workload account baseline | Workload owner | Config resources and Terraform state |

## Routine Checks

### Per change

- Review Terraform plans for replacement and privilege expansion.
- Confirm static checks pass.
- Confirm the post-apply plan has no changes.
- Confirm audit delivery remains healthy.

### Monthly

- Review Identity Center assignments and break-glass access.
- Review high-severity findings and unresolved Config noncompliance.
- Review budgets, unexpected Regions, and untagged resources.
- Check state-bucket access logs, versioning, and lifecycle behavior.

### Quarterly

- Test break-glass access and rotate its credentials.
- Restore a non-production state version.
- Test removal of a faulty SCP attachment.
- Review provider and Terraform version upgrades.
- Confirm documentation matches deployed resources.

## Incident Priorities

1. Preserve CloudTrail and relevant service logs.
2. Contain affected identities, roles, or accounts.
3. Maintain access to the Security account and audit storage.
4. Determine whether organization policies or CI trust were modified.
5. Recover through reviewed Terraform changes where possible.
6. Document the timeline, affected resources, and follow-up controls.

## Retention and Teardown

Normal environment teardown must not delete the central audit bucket, its KMS
key, or Terraform state automatically. These resources require an explicit,
separately reviewed retention decision. Workload VPCs, budgets, DNS associations,
and account-local baselines can be removed in dependency order after evidence is
preserved.

Closing AWS accounts, deleting the AWS Organization, and permanently deleting
audit evidence are administrative procedures outside Terraform's routine
teardown workflow.

# Platform Access Model

## Authentication

Humans authenticate through IAM Identity Center. Workloads and CI use IAM roles
with short-lived credentials. Long-lived IAM users and access keys are not part
of the normal access path.

## Permission Sets

| Permission set | Session | Management | Security | Shared Services | Development | Production |
|---|---:|---|---|---|---|---|
| Organization Administrator | 1 hour | Administer Organizations and billing settings | None | None | None | None |
| Platform Engineer | 1 hour | Read only | Read only | Administrator | Administrator | Power user |
| Security Auditor | 1 hour | Read only | Security administrator | Read only | Security read only | Security read only |
| Read Only | 1 hour | Read only | Read only | Read only | Read only | Read only |

Production applies use the dedicated `macp-prod-terraform-apply` role and require
a reviewed saved plan. Routine users do not receive standing administrator access
to Production.

## Requirements

- Require MFA in the identity provider for every human permission set.
- Limit routine sessions to one hour.
- Assign access to groups, not individual users.
- Review assignments monthly and remove unused access immediately.
- Do not use the management account for workloads or routine engineering.
- Use GitHub OIDC for CI; never store AWS access keys in repository secrets.

The deployment-role module does not require the IAM `MultiFactorAuthPresent`
condition for Identity Center sessions because MFA is enforced upstream by
Identity Center. Enable that condition only for direct IAM principals that can
provide the STS MFA context.

## Verification

For each assigned permission set, sign in through the AWS access portal, select
the intended account and role, and run:

```bash
aws sts get-caller-identity
```

Confirm the returned account ID and assumed-role ARN match the intended access.
Then verify a permitted read operation succeeds and an intentionally prohibited
operation is denied. Never use a destructive request as an access test.

For a deployment role, verify trust without changing infrastructure:

```bash
aws sts assume-role \
  --role-arn "arn:aws:iam::<account-id>:role/<role-name>" \
  --role-session-name access-verification
```

Record only the account ID, role ARN, time, and result. Do not record returned
credentials.


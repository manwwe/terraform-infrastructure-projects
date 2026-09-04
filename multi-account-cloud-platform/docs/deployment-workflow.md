# Deployment Workflow

## Dependency Order

Deploy roots in this order:

1. `bootstrap`
2. `live/organization`
3. `live/security`
4. `live/shared-services`
5. `live/workloads/development`
6. `live/workloads/production`

Reverse the order for teardown, subject to the retained-resource rules in the
future teardown runbook.

## Standard Change Workflow

1. Authenticate through IAM Identity Center or CI OIDC.
2. Select exactly one Terraform root module.
3. Run formatting, initialization, validation, tests, linting, and security
   scanning.
4. Refresh remote state and create a saved plan.
5. Review resource replacements, IAM changes, policy changes, and estimated cost.
6. Apply the exact saved plan after the required approval.
7. Run the root's smoke checks.
8. Run a second plan and require `No changes`.
9. Record verified evidence in documentation.

## Promotion Rules

- Reusable module changes are tested locally before account deployment.
- Security controls and workload baselines are deployed to Development first.
- Production uses the same reviewed module revision as Development.
- A plan is not reusable after source code, provider locks, variables, or remote
  state change.
- Organization-wide policy attachment requires a separate review from ordinary
  workload changes.

## Configuration Inputs

Commit only `terraform.tfvars.example` files with non-sensitive example values.
Supply real account IDs, Regions, notification endpoints, and role principals
through ignored local files or protected CI environment variables.

Expected shared inputs include:

- Organization and account IDs
- Primary and approved AWS Regions
- State bucket and KMS key identifiers
- Identity Center and CI principal identifiers
- Budget threshold and notification destination
- Project name, owner, and required tags

## Rollback

Terraform does not provide a universal rollback operation. For a failed or
undesired change:

1. Preserve logs and the failed plan output.
2. Inspect state and actual AWS resources.
3. Revert the configuration change in Git when appropriate.
4. Generate and review a new plan.
5. Apply only the corrective plan.
6. Restore an older state object only when state itself is damaged, not merely
   because deployed infrastructure is incorrect.

Never rerun a failed apply blindly, edit state manually without a backup, or
detach a protective policy before identifying the affected accounts.

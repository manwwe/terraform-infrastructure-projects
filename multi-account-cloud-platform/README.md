# Multi-Account Cloud Platform

> **Status:** Foundation implemented through Production and CI; Security, Shared
> Services, Development, and Production plans are prepared but not applied.

This project builds a small AWS multi-account foundation with Terraform. It is
intended as a portfolio project, so the design demonstrates account isolation,
central governance, reusable infrastructure, and automated validation without
trying to reproduce a full enterprise landing zone.

## Target Architecture

- One AWS Organization
- A minimally used management account
- Security and shared-services organizational units
- Development and production workload accounts
- Central Terraform state in the shared-services account
- Central organization audit logs in the security account
- IAM Identity Center for human access
- Reusable Terraform modules and account-specific root configurations
- CI checks for formatting, validation, security, and Terraform plans

See [Architecture](docs/architecture.md) for the complete design and
[Implementation plan](docs/implementation-plan.md) for the ordered build steps.

## Repository Layout

```text
multi-account-cloud-platform/
├── README.md
├── bootstrap/                 Remote-state prerequisites
├── docs/                     Architecture and operating guides
├── live/                     Deployable Terraform root modules
│   ├── organization/
│   ├── security/
│   ├── shared-services/
│   └── workloads/
│       ├── development/
│       └── production/
├── modules/                  Reusable Terraform modules
└── tests/                    Static and Terraform tests
```

Reusable modules have Terraform tests. Deployable roots use separate encrypted
S3 state keys and assume account-specific roles.

## Local Validation

```bash
make fmt
make test
bash tests/check-documentation.sh
```

The verified local suite currently contains 11 passing Terraform test runs
across nine modules. `terraform validate` also passes for the Shared Services,
Development, and Production roots. Install TFLint and Trivy before running the
complete `make check` target.

No saved plan has been applied for Tasks 11–17. Review the cost impact—especially
NAT gateways, AWS Config, GuardDuty, Security Hub, CloudWatch Logs, KMS, and S3—
before applying any root.

## GitHub Environments

Create protected environments named `organization`, `security`,
`shared-services`, `development`, and `production`. Store these values in each
environment:

- Secret `AWS_PLAN_ROLE_ARN`
- Secret `AWS_APPLY_ROLE_ARN`
- Secret `STATE_BUCKET_NAME`
- Secret `STATE_KMS_KEY_ARN`
- Secret `TFVARS_JSON`
- Variable `AWS_REGION`

Require reviewers for apply-sensitive environments. Planning and applying use
GitHub OIDC; do not create GitHub access keys. The manual apply workflow requires
the successful plan run ID and the exact commit SHA that created the plan.

## Documentation

- [Architecture](docs/architecture.md)
- [Implementation plan](docs/implementation-plan.md)
- [Deployment workflow](docs/deployment-workflow.md)
- [Security and operations](docs/security-and-operations.md)
- [Access model](docs/access.md)
- [Tasks 12–16 deployment order](docs/runbooks/tasks-12-14-deployment.md)
- [State recovery](docs/runbooks/state-recovery.md)
- [Policy recovery](docs/runbooks/policy-recovery.md)
- [Account compromise response](docs/runbooks/account-compromise.md)
- [Teardown guide](docs/teardown.md)

## Scope Boundaries

The first version intentionally excludes AWS Control Tower, custom account
vending, a transit gateway, centralized egress, cross-Region disaster recovery,
and application workloads. These can be added later only if the completed
foundation demonstrates a clear need for them.

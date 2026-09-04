# Multi-Account Cloud Platform

> **Status:** Architecture defined; implementation not started

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

## Planned Repository Layout

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

Only documentation is present initially. Terraform directories will be added
incrementally according to the implementation plan.

## Documentation

- [Architecture](docs/architecture.md)
- [Implementation plan](docs/implementation-plan.md)
- [Deployment workflow](docs/deployment-workflow.md)
- [Security and operations](docs/security-and-operations.md)

## Scope Boundaries

The first version intentionally excludes AWS Control Tower, custom account
vending, a transit gateway, centralized egress, cross-Region disaster recovery,
and application workloads. These can be added later only if the completed
foundation demonstrates a clear need for them.


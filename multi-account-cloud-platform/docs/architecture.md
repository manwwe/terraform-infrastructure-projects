# Multi-Account Cloud Platform Architecture

## 1. Purpose

Build a small, understandable AWS multi-account foundation with Terraform. The
platform must isolate production from development, centralize audit evidence,
provide controlled access, and demonstrate a repeatable deployment workflow.

## 2. Design Principles

- Keep the management account free of workloads.
- Separate security duties from shared platform services.
- Isolate development and production with separate AWS accounts.
- Prefer AWS-managed services and organization-wide controls.
- Give each Terraform root module one clear ownership boundary.
- Store no credentials or account-specific secrets in Git.
- Add controls only when they protect a defined risk.

## 3. Account and Organizational Unit Model

```text
AWS Organization
├── Management account
├── Security OU
│   └── Security account
├── Infrastructure OU
│   └── Shared-services account
└── Workloads OU
    ├── Development account
    └── Production account
```

| Account | Responsibility | Must not contain |
|---|---|---|
| Management | AWS Organizations, organizational policies, billing ownership | Application workloads or shared tooling |
| Security | Organization CloudTrail destination, AWS Config aggregation, security findings | CI runners or application workloads |
| Shared services | Terraform state, CI deployment roles, shared DNS delegation | Production application resources |
| Development | Non-production workloads and safe experimentation | Production data |
| Production | Production workloads | Development experiments |

Account creation is documented but not automated in version one. Existing AWS
accounts are imported into the organization root configuration so that the
project does not depend on programmatic payment or account-enrollment workflows.

## 4. Terraform Boundaries

Each directory under `live/` is an independently planned and applied Terraform
root. This limits blast radius and prevents an organization change from being
coupled to a workload-account change.

| Root module | Provider target | Owns |
|---|---|---|
| `live/organization` | Management account | OUs, account placement, service control policies |
| `live/security` | Security account | Audit bucket, Config aggregator, security services |
| `live/shared-services` | Shared-services account | State backend, deployment roles, shared DNS |
| `live/workloads/development` | Development account | Development baseline and sample network |
| `live/workloads/production` | Production account | Production baseline and sample network |

Reusable modules will live under `modules/`:

- `organization`: organizational units and account placement
- `service-control-policies`: a small set of preventative guardrails
- `account-baseline`: password policy, account aliases, Config recorder, and
  organization audit integration
- `audit-logging`: encrypted central log storage and CloudTrail
- `security-services`: delegated administration and finding aggregation
- `terraform-state`: encrypted, versioned state storage and locking
- `deployment-role`: least-privilege cross-account role trust
- `vpc`: a small two-Availability-Zone workload network

Modules expose narrow inputs and outputs. Root modules provide account IDs,
Regions, names, and environment-specific settings.

## 5. State and Deployment Model

The bootstrap stack creates an encrypted, versioned S3 bucket in the
shared-services account. Every root module uses S3 native lock files and a
distinct state key:

```text
organization/terraform.tfstate
security/terraform.tfstate
shared-services/terraform.tfstate
workloads/development/terraform.tfstate
workloads/production/terraform.tfstate
```

State encryption uses a customer-managed KMS key. Bucket policies require TLS,
deny public access, and restrict access to deployment roles. Bootstrap state is
kept locally only long enough to migrate it into its own remote state key.

Engineers authenticate through IAM Identity Center. Terraform assumes a named
deployment role in the target account. CI uses OpenID Connect federation and
assumes the same class of role without storing long-lived AWS keys.

## 6. Governance and Security Controls

Version one implements four service control policy themes:

1. Deny leaving the organization.
2. Deny disabling or deleting central audit controls.
3. Deny use of unapproved AWS Regions, with global-service exceptions.
4. Deny public S3 access settings from being weakened.

Policies are attached to the narrowest applicable OU. They are first tested on
the Development account and are never attached to the organization root during
initial development.

Organization CloudTrail delivers management events to the Security account.
AWS Config records supported resources in every member account and aggregates
results centrally. Security Hub and GuardDuty use the Security account as their
delegated administrator when supported by the active AWS Organization setup.

## 7. Networking and DNS

Version one does not build centralized networking. Each workload account owns a
two-Availability-Zone VPC through the reusable `vpc` module. Development uses a
single NAT gateway to limit cost; production uses one NAT gateway per
Availability Zone to avoid a single-zone dependency.

The shared-services account owns an optional private Route 53 parent zone.
Workload accounts own and manage their environment-specific zones. Cross-account
zone authorization and association are explicit Terraform resources.

Transit Gateway, centralized inspection, centralized egress, and hybrid
connectivity are outside the initial scope.

## 8. Data and Control Flow

1. A developer signs in through IAM Identity Center.
2. Terraform initializes against the shared state bucket.
3. Terraform assumes the deployment role for one root module's target account.
4. CI or the developer runs validation and creates a saved plan.
5. An authorized apply updates only that root module's resources.
6. CloudTrail sends management events to the Security account.
7. AWS Config and security services aggregate posture and findings centrally.

## 9. Failure Handling and Recovery

- S3 versioning preserves earlier Terraform state objects.
- S3 native state locking prevents concurrent applies to the same root.
- Saved plans are discarded when the source revision or remote state changes.
- A failed apply is followed by a fresh plan; it is never retried blindly.
- Organization policies are introduced in Development before Production.
- Break-glass roles are created manually, protected with MFA, excluded from
  routine use, and monitored through CloudTrail.
- Audit-log lifecycle rules transition older logs to lower-cost storage without
  allowing routine deletion.

## 10. Validation Strategy

Every change runs:

- `terraform fmt -check -recursive`
- `terraform init -backend=false` for affected modules
- `terraform validate` for affected roots and modules
- `terraform test` for module behavior that Terraform can test locally
- TFLint for provider and configuration errors
- Checkov or Trivy configuration scanning for security regressions
- Shell-based checks for required documentation and forbidden placeholders

Account-level integration tests are performed in Development before the same
module version is promoted to Production. Destructive organization-policy tests
must use a disposable member account when available.

## 11. Cost Controls

Budgets are configured in every member account with email notification supplied
outside source control. Cost allocation tags are standardized as `Project`,
`Environment`, `Owner`, and `ManagedBy`. Expensive optional services remain
disabled until their validation step is reached.

The main recurring costs are expected to come from NAT gateways, AWS Config,
CloudTrail data events if enabled later, and security services. The deployment
guide must show how to disable or destroy optional test resources safely.

## 12. Explicit Non-Goals

- A complete enterprise landing zone
- AWS Control Tower customization
- Automated account vending
- Application deployment
- Kubernetes or container orchestration
- Hybrid networking
- Multi-Region active-active services
- Automatic remediation of security findings

## 13. Completion Criteria

The project is complete when all five accounts have the intended placement and
baseline, all Terraform roots use remote state, audit and security evidence is
visible in the Security account, CI produces plans without static-analysis
errors, Development and Production networks deploy independently, and the
documented recovery and teardown procedures have been exercised in Development.

# Multi-Account Cloud Platform Implementation Plan

> **For agentic workers:** Implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a small AWS multi-account foundation with isolated workload accounts, centralized audit and security services, reusable Terraform modules, and automated validation.

**Architecture:** Use five AWS accounts grouped into Security, Infrastructure, and Workloads organizational units. Deploy independent Terraform roots through cross-account roles, with encrypted remote state in Shared Services and centralized audit evidence in Security.

**Tech Stack:** Terraform 1.16, AWS Organizations, IAM Identity Center, IAM, S3, KMS, CloudTrail, AWS Config, GuardDuty, Security Hub, Route 53, GitHub Actions, TFLint, Checkov or Trivy

---

## Delivery Rules

- Complete phases in order; later roots depend on outputs from earlier phases.
- Run checks locally before every commit.
- Apply organization controls to Development before Production.
- Never store AWS account IDs, notification addresses, credentials, or secrets in
  committed variable files.
- Record real deployment evidence only after the corresponding apply succeeds.

## Phase 1: Project Skeleton and Tooling

### Task 1: Create the repository structure

**Files:**

- Create: `.gitignore`
- Create: `.terraform-version`
- Create: `Makefile`
- Create: `bootstrap/`
- Create: `live/organization/`
- Create: `live/security/`
- Create: `live/shared-services/`
- Create: `live/workloads/development/`
- Create: `live/workloads/production/`
- Create: `modules/`
- Create: `tests/`

- [ ] Add Terraform, plan, local variable, and generated test artifacts to `.gitignore`.
- [ ] Pin the Terraform minor version used by every root.
- [ ] Add `fmt`, `validate`, `test`, `lint`, and `security` Make targets.
- [ ] Run `terraform fmt -check -recursive .`; expect exit status `0`.
- [ ] Commit with `chore: scaffold multi-account platform`.

### Task 2: Define shared conventions

**Files:**

- Create: `docs/naming-and-tagging.md`
- Create: `tests/check-documentation.sh`

- [ ] Define resource naming as `<project>-<environment>-<purpose>`.
- [ ] Define required tags: `Project`, `Environment`, `Owner`, and `ManagedBy`.
- [ ] Add a documentation check that rejects unfinished placeholder markers.
- [ ] Run `bash tests/check-documentation.sh`; expect exit status `0`.
- [ ] Commit with `docs: define platform conventions`.

## Phase 2: Remote-State Bootstrap

### Task 3: Build the state module

**Files:**

- Create: `modules/terraform-state/main.tf`
- Create: `modules/terraform-state/variables.tf`
- Create: `modules/terraform-state/outputs.tf`
- Create: `modules/terraform-state/versions.tf`
- Create: `modules/terraform-state/tests/state.tftest.hcl`

- [ ] Write tests asserting S3 versioning, KMS encryption, public-access blocks,
  a TLS-only bucket policy, and backend support for S3 native lock files.
- [ ] Run `terraform -chdir=modules/terraform-state test`; expect the new tests to fail.
- [ ] Implement the minimum resources required by the tests.
- [ ] Run the module tests again; expect all tests to pass.
- [ ] Commit with `feat(state): add secure remote state module`.

### Task 4: Bootstrap shared state

**Files:**

- Create: `bootstrap/main.tf`
- Create: `bootstrap/providers.tf`
- Create: `bootstrap/variables.tf`
- Create: `bootstrap/outputs.tf`
- Create: `bootstrap/terraform.tfvars.example`

- [ ] Instantiate the state module in the Shared-services account.
- [ ] Apply with local state and verify bucket versioning, encryption, and locking.
- [ ] Add an S3 backend block and migrate bootstrap state to
  `bootstrap/terraform.tfstate`.
- [ ] Run a no-change plan; expect `No changes`.
- [ ] Commit with `feat(state): bootstrap shared Terraform backend`.

## Phase 3: Organization Foundation

### Task 5: Create the organization module

**Files:**

- Create: `modules/organization/main.tf`
- Create: `modules/organization/variables.tf`
- Create: `modules/organization/outputs.tf`
- Create: `modules/organization/tests/organization.tftest.hcl`

- [ ] Write tests for Security, Infrastructure, and Workloads OUs and deterministic
  account placement.
- [ ] Run the tests and confirm they fail before implementation.
- [ ] Implement OU resources and account-to-OU mapping inputs.
- [ ] Run the tests and confirm they pass.
- [ ] Commit with `feat(organization): define organizational structure`.

### Task 6: Add service control policies

**Files:**

- Create: `modules/service-control-policies/main.tf`
- Create: `modules/service-control-policies/variables.tf`
- Create: `modules/service-control-policies/outputs.tf`
- Create: `modules/service-control-policies/policies/`
- Create: `modules/service-control-policies/tests/policies.tftest.hcl`

- [ ] Test policies that protect organization membership, audit services, approved
  Regions, and S3 public-access settings.
- [ ] Implement each policy as a separate JSON document and attachment map.
- [ ] Validate exception lists for global services and break-glass administration.
- [ ] Run Terraform tests and static security scanning.
- [ ] Commit with `feat(organization): add preventive guardrails`.

### Task 7: Assemble the organization root

**Files:**

- Create: `live/organization/backend.tf`
- Create: `live/organization/main.tf`
- Create: `live/organization/providers.tf`
- Create: `live/organization/variables.tf`
- Create: `live/organization/outputs.tf`
- Create: `live/organization/terraform.tfvars.example`

- [ ] Configure the management-account provider and remote-state key.
- [ ] Import existing member accounts rather than creating new accounts.
- [ ] Place accounts in their intended OUs.
- [ ] Attach initial policies only to the Development account's OU path.
- [ ] Save and review the plan before applying.
- [ ] Verify account placement with the AWS Organizations API.
- [ ] Commit with `feat(organization): deploy account hierarchy`.

## Phase 4: Cross-Account Access

### Task 8: Create deployment roles

**Files:**

- Create: `modules/deployment-role/main.tf`
- Create: `modules/deployment-role/variables.tf`
- Create: `modules/deployment-role/outputs.tf`
- Create: `modules/deployment-role/tests/role.tftest.hcl`

- [x] Test that role trust accepts only approved IAM Identity Center and CI OIDC
  principals.
- [x] Test session duration, external conditions, and permissions boundaries.
- [x] Implement separate plan and apply roles where practical.
- [x] Verify an unapproved principal is absent from both role trust policies.
- [x] Commit with `feat(iam): add cross-account deployment roles`.

### Task 9: Document human and emergency access

**Files:**

- Create: `docs/access.md`
- Create: `docs/runbooks/break-glass-access.md`

- [x] Map administrator, platform engineer, security auditor, and read-only
  permission sets to the correct accounts.
- [x] Define MFA and short-session requirements.
- [x] Document break-glass credential custody, use, monitoring, and rotation.
- [ ] Test sign-in and role assumption in each account.
- [x] Commit with `docs(iam): define platform access model`.

## Phase 5: Central Audit and Security

### Task 10: Build centralized audit logging

**Files:**

- Create: `modules/audit-logging/main.tf`
- Create: `modules/audit-logging/variables.tf`
- Create: `modules/audit-logging/outputs.tf`
- Create: `modules/audit-logging/tests/audit.tftest.hcl`

- [x] Test encrypted, versioned, access-logged storage with public access blocked.
- [x] Test organization CloudTrail, log validation, and restricted bucket policies.
- [x] Implement lifecycle transitions without routine delete permissions.
- [ ] Deliver a test event and verify its object in the Security account.
- [x] Commit with `feat(audit): centralize organization audit logs`.

### Task 11: Build account baselines and security aggregation

**Files:**

- Create: `modules/account-baseline/`
- Create: `modules/security-services/`
- Create: `live/security/`

- [x] Test Config recorders and delivery channels for member accounts.
- [x] Configure the Security account as the Config aggregation destination.
- [x] Define GuardDuty, Security Hub, and Config delegated administration.
- [ ] Enroll Development first and verify findings reach the Security account.
- [ ] Enroll the remaining member accounts after validation.
- [ ] Run a no-change plan for every affected root.
- [x] Commit with `feat(security): add centralized security baseline`.

## Phase 6: Shared Services

### Task 12: Assemble shared services

**Files:**

- Create: `modules/private-dns/`
- Create: `live/shared-services/backend.tf`
- Create: `live/shared-services/main.tf`
- Create: `live/shared-services/providers.tf`
- Create: `live/shared-services/variables.tf`
- Create: `live/shared-services/outputs.tf`

- [x] Manage the existing state resources without attempting replacement.
- [x] Add CI OIDC providers and narrowly scoped deployment-role trust.
- [x] Create the optional private parent DNS zone.
- [ ] Verify remote-state access from every deployment role.
- [x] Commit with `feat(shared-services): add platform services`.

## Phase 7: Workload Account Foundations

### Task 13: Create the VPC module

**Files:**

- Create: `modules/vpc/main.tf`
- Create: `modules/vpc/variables.tf`
- Create: `modules/vpc/outputs.tf`
- Create: `modules/vpc/tests/vpc.tftest.hcl`

- [x] Test two Availability Zones, public and private subnets, flow logs, and no
  default security-group ingress or egress.
- [x] Test one NAT gateway for Development and one per Availability Zone for
  Production.
- [x] Implement the network resources and stable subnet outputs.
- [ ] Run Terraform tests, TFLint, and security scanning.
- [x] Commit with `feat(network): add workload VPC module`.

### Task 14: Deploy Development baseline

**Files:**

- Create: `live/workloads/development/backend.tf`
- Create: `live/workloads/development/main.tf`
- Create: `live/workloads/development/providers.tf`
- Create: `live/workloads/development/variables.tf`
- Create: `live/workloads/development/outputs.tf`
- Create: `live/workloads/development/terraform.tfvars.example`

- [ ] Apply the account baseline, deployment roles, budget, DNS association, and
  cost-optimized VPC.
- [ ] Verify Config recording, CloudTrail delivery, flow logs, role assumption,
  state access, and budget configuration.
- [ ] Destroy and restore the disposable VPC to test recovery instructions.
- [ ] Finish with a no-change plan.
- [x] Commit with `feat(development): deploy workload foundation`.

### Task 15: Deploy Production baseline

**Files:**

- Create: `live/workloads/production/backend.tf`
- Create: `live/workloads/production/main.tf`
- Create: `live/workloads/production/providers.tf`
- Create: `live/workloads/production/variables.tf`
- Create: `live/workloads/production/outputs.tf`
- Create: `live/workloads/production/terraform.tfvars.example`

- [ ] Reuse the tested module versions and production-specific inputs.
- [ ] Require a reviewed saved plan before apply.
- [ ] Deploy the baseline and one NAT gateway per Availability Zone.
- [ ] Verify security telemetry and state access from the Security and
  Shared-services accounts.
- [ ] Finish with a no-change plan.
- [ ] Commit with `feat(production): deploy workload foundation`.

## Phase 8: CI and Operational Readiness

### Task 16: Add continuous integration

**Files:**

- Create: `.github/workflows/terraform-checks.yml`
- Create: `.github/workflows/terraform-plan.yml`
- Create: `.github/workflows/terraform-apply.yml`

- [ ] Run formatting, validation, Terraform tests, TFLint, and security scanning
  on pull requests.
- [ ] Generate plans only for changed roots and retain them as short-lived
  artifacts.
- [ ] Require protected-environment approval for applies.
- [ ] Authenticate exclusively through GitHub OIDC.
- [ ] Test failure paths for invalid formatting and insecure configuration.
- [ ] Commit with `ci: add Terraform validation and deployment workflows`.

### Task 17: Complete operating runbooks

**Files:**

- Create: `docs/runbooks/state-recovery.md`
- Create: `docs/runbooks/policy-recovery.md`
- Create: `docs/runbooks/account-compromise.md`
- Create: `docs/teardown.md`
- Modify: `README.md`

- [ ] Exercise recovery of an earlier S3 state version in Development.
- [ ] Exercise removal of a faulty policy attachment.
- [ ] Document containment and evidence-preservation steps for account compromise.
- [ ] Document dependency-aware teardown and resources intentionally retained.
- [ ] Update the README status and validation commands using verified results.
- [ ] Run all local checks and obtain no-change plans for every deployed root.
- [ ] Commit with `docs: complete platform operations guide`.

## Final Acceptance Checklist

- [ ] All accounts are in their intended organizational units.
- [ ] Management contains no project workloads.
- [ ] Every root uses encrypted remote state and locking.
- [ ] Development and Production can be planned and deployed independently.
- [ ] Organization audit logs arrive in the Security account.
- [ ] Config, GuardDuty, and Security Hub aggregate centrally as designed.
- [ ] Human and CI access use federation rather than long-lived access keys.
- [ ] Preventative policies have been tested in Development.
- [ ] CI checks and reviewed apply workflows pass.
- [ ] Recovery and teardown procedures have been exercised in Development.
- [ ] Documentation contains no unverified completion claims or placeholders.

# Project Documentation Refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace stale design-phase documentation with accurate development architecture, operating guides, and editable diagram assets for the deployed Snake application.

**Architecture:** The README will route readers to focused architecture, security, testing, deployment, recovery, and teardown documents. All content will describe only the current HTTP development environment; a Draw.io source and exported SVG will visualize the same implemented request, management, secret, database, and egress paths.

**Tech Stack:** Markdown, Draw.io XML, SVG, Terraform 1.16, AWS VPC/ALB/EC2 Auto Scaling/RDS/Systems Manager/Secrets Manager

---

## File Map

- Modify `README.md`: present the repository project accurately.
- Modify `docs/architecture.md`: document the implemented topology and embed the diagram.
- Modify `docs/security.md`: separate implemented controls from future work.
- Modify `docs/testing.md`: list real checks and repeatable commands.
- Modify `docs/implementation-plan.md`: mark completed development phases and remaining work.
- Create `docs/deployment.md`: document bootstrap, plan, apply, and verification.
- Create `docs/recovery.md`: document safe diagnosis and recovery workflows.
- Create `docs/teardown.md`: document environment-first destruction without prematurely deleting state.
- Create `docs/diagrams/development-architecture.drawio`: editable architecture source.
- Create `docs/diagrams/development-architecture.svg`: rendered architecture diagram.

### Task 1: Refresh the Project Entry Point and Architecture

**Files:**
- Modify: `multi-environment-web-app/README.md`
- Modify: `multi-environment-web-app/docs/architecture.md`

- [ ] **Step 1: Replace the README status and overview**

Write a README with these exact sections and facts:

```markdown
# Multi-Environment Web Application

> **Status:** Development environment deployed and verified

This project runs a small Flask Snake game on AWS. Scores are stored in Amazon
RDS for PostgreSQL. Terraform creates a three-tier network, an internet-facing
Application Load Balancer, private EC2 instances in an Auto Scaling group, and a
private database.

## Implemented Architecture

- One VPC across two Availability Zones
- Public subnets for the Application Load Balancer and NAT gateway
- Private application subnets for EC2 Auto Scaling
- Private database subnets for RDS PostgreSQL
- Systems Manager administration without SSH
- RDS-managed credentials in Secrets Manager
- Encrypted, versioned S3 remote state with native locking

Client traffic currently uses HTTP on port 80. HTTPS, DNS, production, CI, and
CloudWatch application log shipping are outside the current implementation.
```

Continue with a repository-layout tree, prerequisites (`Terraform 1.16`, AWS CLI,
credentials, and an AWS account), a quick-start linking to `docs/deployment.md`,
the application URL output command, validation commands, documentation links, and
the explicit limitations above. Never include deployed IDs or endpoints.

- [ ] **Step 2: Rewrite the architecture page in present tense**

Include these sections in `docs/architecture.md`:

```markdown
# Development Architecture

![Development AWS architecture](diagrams/development-architecture.svg)

## Request Flow

1. A browser sends HTTP traffic to the public Application Load Balancer.
2. The listener forwards to healthy Nginx targets on port 80.
3. Nginx proxies application requests to Gunicorn and Flask.
4. Flask retrieves credentials through the EC2 role and stores scores in RDS.

## Availability and Cost Choices

The ALB and Auto Scaling group span two Availability Zones. Development keeps one
EC2 instance, one NAT gateway, and a Single-AZ RDS instance to control cost.
```

Also describe subnet tiers, security-group hops, Systems Manager, Secrets Manager,
remote state, current failure behavior, and the absence of HTTPS and production.

- [ ] **Step 3: Check links and stale architecture claims**

Run:

```bash
rg -n "Design phase|will terminate HTTPS|accepts HTTPS|CloudWatch will" multi-environment-web-app/README.md multi-environment-web-app/docs/architecture.md
```

Expected: no matches.

- [ ] **Step 4: Commit the entry-point documentation**

```bash
git add multi-environment-web-app/README.md multi-environment-web-app/docs/architecture.md
git commit -m "docs: describe deployed development architecture"
```

### Task 2: Correct Security, Testing, and Roadmap Documentation

**Files:**
- Modify: `multi-environment-web-app/docs/security.md`
- Modify: `multi-environment-web-app/docs/testing.md`
- Modify: `multi-environment-web-app/docs/implementation-plan.md`

- [ ] **Step 1: Rewrite security documentation around implemented controls**

Use these headings and requirements:

```markdown
# Security

## Implemented Controls

- Only the ALB accepts public application traffic.
- EC2 instances and RDS have no public addresses.
- Security-group references enforce ALB → application → database traffic.
- EC2 requires IMDSv2 and uses encrypted EBS storage.
- RDS storage and remote Terraform state are encrypted.
- Systems Manager replaces public SSH access.
- The instance role can read only the configured RDS-managed secret.

## Current Limitations

Client traffic uses unencrypted HTTP. HTTPS and DNS are outside the current scope.
The application uses the RDS master credential; a production design should use a
restricted application user.

## Production Safeguards Not Yet Implemented

Production, Multi-AZ RDS, deletion protection, longer backups, monitoring alarms,
and stricter operator permissions remain future work.
```

Add short sections covering secrets, administrative access, and sensitive local
files without claiming unimplemented controls exist.

- [ ] **Step 2: Make testing documentation match real tests**

Document exact commands for:

```bash
terraform fmt -check -recursive multi-environment-web-app
terraform -chdir=multi-environment-web-app/environments/dev validate
terraform -chdir=multi-environment-web-app/modules/compute test
terraform -chdir=multi-environment-web-app/modules/load-balancer test
python -m pytest
```

State that the application currently has 28 tests, compute has 6 Terraform test
runs, and load balancing has 4. Mark tests for network, security, IAM, and RDS;
TFLint; security scanning; CI; replacement testing; and production plans as
remaining work.

- [ ] **Step 3: Convert the implementation plan to a status checklist**

Mark foundations, networking, security groups/IAM/Secrets Manager, development
RDS, compute, Flask/Snake, and HTTP load balancing as complete. Keep production,
CloudWatch application/system logging and alarms, CI, broader module tests,
recovery testing, and the final documentation verification as remaining items.
Explicitly mark HTTPS and DNS as out of scope instead of incomplete.

- [ ] **Step 4: Scan for inaccurate security and testing claims**

Run:

```bash
rg -n "HTTPS will|accepts HTTPS|all reusable modules|production plans will run" multi-environment-web-app/docs
```

Expected: no inaccurate present-tense claims; historical design records under
`docs/decisions/` may retain their original decision context.

- [ ] **Step 5: Commit the corrected reference documentation**

```bash
git add multi-environment-web-app/docs/security.md multi-environment-web-app/docs/testing.md multi-environment-web-app/docs/implementation-plan.md
git commit -m "docs: align security and testing guidance"
```

### Task 3: Add Deployment, Recovery, and Teardown Guides

**Files:**
- Create: `multi-environment-web-app/docs/deployment.md`
- Create: `multi-environment-web-app/docs/recovery.md`
- Create: `multi-environment-web-app/docs/teardown.md`

- [ ] **Step 1: Write the deployment guide**

Use this operational sequence:

```markdown
# Development Deployment

## Prerequisites

Install Terraform 1.16 and AWS CLI v2, authenticate to the intended AWS account,
and confirm the caller with `aws sts get-caller-identity`.

## Bootstrap Remote State

1. Copy `bootstrap/terraform.tfvars.example` and `bootstrap/backend.hcl.example`
   to their ignored local filenames.
2. Run `terraform init`, `terraform plan -out=tfplan`, inspect with
   `terraform show tfplan`, and apply only the reviewed plan.
3. Follow `bootstrap/README.md` to migrate bootstrap state.

## Deploy Development

1. Create ignored `environments/dev/backend.hcl` and `terraform.tfvars` files.
2. Run `terraform init -backend-config=backend.hcl`.
3. Run `terraform validate` and the module/application tests.
4. Save and inspect `terraform plan -var-file=terraform.tfvars -out=tfplan`.
5. Apply only with `terraform apply tfplan`.

## Verify

Read `application_load_balancer_dns_name`, open it over HTTP, check `/health`,
submit a Snake score, refresh the leaderboard, inspect target health, and verify
the EC2 instance is online in Systems Manager.
```

Include concrete safe commands for each step and a warning that plans are
environment- and time-specific.

- [ ] **Step 2: Write the recovery guide**

Cover these exact scenarios with non-secret diagnostic commands:

- Failed apply where an ASG later self-recovers: inspect scaling activities,
  confirm instance/target health, run a new plan, and use `terraform untaint` only
  when the resource exists and matches configuration.
- Unhealthy ALB target: inspect target health, security groups, cloud-init,
  `snake-app`, Nginx, and `/health` through Systems Manager.
- Application/database failure: inspect service logs and RDS status without
  printing the secret value.
- State locking: identify the active operation before considering recovery; never
  delete a lock while another Terraform process is running.

- [ ] **Step 3: Write the teardown guide**

Specify this order:

1. Back up scores if needed.
2. In `environments/dev`, create and inspect a destroy plan with
   `terraform plan -destroy -var-file=terraform.tfvars -out=destroy.tfplan`.
3. Apply only that reviewed destroy plan.
4. Confirm environment resources are gone and state is retained.
5. Keep the bootstrap state bucket by default. Explain that removing it is a
   separate, intentional operation requiring emptying versioned objects and
   changing deletion safeguards.

Never present a broad recursive deletion command.

- [ ] **Step 4: Verify the operational guides do not expose deployment data**

Run:

```bash
rg -n "924594387630|arn:aws:|\.elb\.amazonaws\.com|rds\.amazonaws\.com|100\.25\.18\.118" multi-environment-web-app/docs multi-environment-web-app/README.md
```

Expected: no matches outside generic examples that use explicit placeholders; use
no concrete account IDs or current endpoints.

- [ ] **Step 5: Commit the operational guides**

```bash
git add multi-environment-web-app/docs/deployment.md multi-environment-web-app/docs/recovery.md multi-environment-web-app/docs/teardown.md
git commit -m "docs: add development operations guides"
```

### Task 4: Create and Embed the Architecture Diagram

**Files:**
- Create: `multi-environment-web-app/docs/diagrams/development-architecture.drawio`
- Create: `multi-environment-web-app/docs/diagrams/development-architecture.svg`
- Modify: `multi-environment-web-app/docs/architecture.md`

- [ ] **Step 1: Create the Draw.io source**

Create valid uncompressed Draw.io XML with one page named `Development`. Use
containers for AWS Region, VPC, and the two Availability Zones; use labeled boxes
for public, application, and database subnets. Place internet clients and the
internet gateway before an ALB spanning both public subnets, an Auto Scaling group
spanning both application subnets, and RDS in the database subnet group. Place the
single NAT gateway in the first public subnet and show Systems Manager and Secrets
Manager outside the VPC boundary.

Use arrows labeled `HTTP :80`, `HTTP :80`, `PostgreSQL :5432`, `SSM`, `GetSecretValue`,
and `Outbound via NAT`. Do not include resource IDs, account IDs, or endpoints.

- [ ] **Step 2: Export an accessible SVG**

Export the same diagram to a responsive SVG with a white canvas, dark text,
high-contrast subnet colors, arrow markers, embedded labels, and this title and
description:

```xml
<title>Development AWS architecture</title>
<desc>Internet traffic enters an Application Load Balancer in public subnets, reaches private EC2 instances, and stores Snake scores in private RDS PostgreSQL.</desc>
```

- [ ] **Step 3: Embed the SVG**

Ensure `docs/architecture.md` contains:

```markdown
![Development AWS architecture](diagrams/development-architecture.svg)
```

- [ ] **Step 4: Parse and render both assets**

Run:

```bash
xmllint --noout multi-environment-web-app/docs/diagrams/development-architecture.drawio
xmllint --noout multi-environment-web-app/docs/diagrams/development-architecture.svg
```

Render the SVG to PNG with an available renderer and inspect it for clipped text,
crossing labels, unreadable arrows, and mismatch with the documented architecture.

- [ ] **Step 5: Commit the diagram assets**

```bash
git add multi-environment-web-app/docs/architecture.md multi-environment-web-app/docs/diagrams
git commit -m "docs: add development architecture diagram"
```

### Task 5: Final Documentation Verification

**Files:**
- Verify all files listed above.

- [ ] **Step 1: Verify Markdown links**

Run a local link-check script that extracts relative Markdown targets from all
project Markdown files, ignores URL and anchor targets, and fails if a referenced
repository path does not exist.

Expected: no broken relative links.

- [ ] **Step 2: Run implementation regression checks**

Run:

```bash
terraform fmt -check -recursive multi-environment-web-app
terraform -chdir=multi-environment-web-app/environments/dev validate
terraform -chdir=multi-environment-web-app/modules/compute test
terraform -chdir=multi-environment-web-app/modules/load-balancer test
python -m pytest
git diff --check
```

Expected: Terraform checks pass, 6 compute test runs pass, 4 load-balancer test
runs pass, 28 Python tests pass, and no whitespace errors are reported.

- [ ] **Step 3: Review scope and sensitive-data scans**

Confirm the changed documentation describes development only, calls HTTP current,
marks HTTPS/DNS out of scope, marks production/observability/CI future, and contains
no concrete deployed identifiers or credentials.

- [ ] **Step 4: Commit any verification corrections**

If verification required corrections, stage only the documentation files changed
by those corrections and commit:

```bash
git commit -m "docs: finalize project operations documentation"
```

If no corrections were required, do not create an empty commit.

- [ ] **Step 5: Summarize the handoff**

Report the documentation and diagram files created or updated, link to the README
and architecture page, list verification results, and state explicitly that no
Terraform apply or destroy command was run.

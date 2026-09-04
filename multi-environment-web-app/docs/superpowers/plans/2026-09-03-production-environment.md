# Production Environment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a separately stateful production Terraform root with enforced Multi-AZ, recovery, capacity, NAT, and restricted-ingress safeguards without applying infrastructure.

**Architecture:** Create `environments/prod` as an independent root that wires the existing modules with explicit production values and a unique S3 state key. Extend the security module only to make its unused HTTPS ingress rule optional, then protect the production contract with mocked-provider Terraform tests and operator documentation.

**Tech Stack:** Terraform 1.16, HashiCorp AWS provider 6.x, Terraform test framework, AWS S3 backend, pytest.

---

### Task 1: Make HTTPS ingress explicit in the security module

**Files:**
- Modify: `modules/security/variables.tf`
- Modify: `modules/security/main.tf`
- Create: `modules/security/tests/security.tftest.hcl`

- [ ] **Step 1: Write tests for HTTP-only and HTTPS-enabled security groups**

Create `modules/security/tests/security.tftest.hcl`:

```hcl
mock_provider "aws" {}

variables {
  name_prefix               = "example-prod"
  vpc_id                    = "vpc-0123456789abcdef0"
  application_port          = 80
  database_port             = 5432
  load_balancer_ingress_cidrs = ["203.0.113.0/24"]
  tags = {
    Environment = "test"
  }
}

run "creates_restricted_http_only_path" {
  command = plan

  variables {
    enable_load_balancer_https = false
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.load_balancer_http) == 1
    error_message = "The load balancer must allow HTTP from each approved CIDR."
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.load_balancer_https) == 0
    error_message = "HTTPS ingress must be absent when HTTPS is disabled."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.application_from_load_balancer.referenced_security_group_id == aws_security_group.load_balancer.id
    error_message = "Application ingress must be restricted to the load balancer security group."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.database_from_application.referenced_security_group_id == aws_security_group.application.id
    error_message = "Database ingress must be restricted to the application security group."
  }
}

run "creates_https_rules_when_enabled" {
  command = plan

  variables {
    enable_load_balancer_https = true
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.load_balancer_https) == 1
    error_message = "HTTPS ingress must be created for approved CIDRs when enabled."
  }
}
```

- [ ] **Step 2: Run the security tests and verify that the new input is rejected**

Run:

```bash
terraform -chdir=modules/security init -backend=false
terraform -chdir=modules/security test
```

Expected: FAIL because `enable_load_balancer_https` is undeclared.

- [ ] **Step 3: Add the HTTPS feature flag**

Append to `modules/security/variables.tf`:

```hcl
variable "enable_load_balancer_https" {
  type        = bool
  description = "Whether approved client CIDRs may reach the load balancer on TCP port 443."
  default     = true
}
```

Change the HTTPS rule iterator in `modules/security/main.tf`:

```hcl
resource "aws_vpc_security_group_ingress_rule" "load_balancer_https" {
  for_each = var.enable_load_balancer_https ? var.load_balancer_ingress_cidrs : []

  security_group_id = aws_security_group.load_balancer.id
  cidr_ipv4         = each.value
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "Allows approved HTTPS traffic."
}
```

- [ ] **Step 4: Format and run the security tests**

Run:

```bash
terraform fmt modules/security
terraform -chdir=modules/security test
```

Expected: PASS, 2 runs.

- [ ] **Step 5: Commit the security-module change**

```bash
git add multi-environment-web-app/modules/security
git commit -m "feat(security): make HTTPS ingress optional"
```

### Task 2: Add the isolated production root

**Files:**
- Create: `environments/prod/terraform.tf`
- Create: `environments/prod/providers.tf`
- Create: `environments/prod/locals.tf`
- Create: `environments/prod/variables.tf`
- Create: `environments/prod/main.tf`
- Create: `environments/prod/outputs.tf`
- Create: `environments/prod/backend.hcl.example`
- Create: `environments/prod/terraform.tfvars.example`
- Create: `environments/prod/templates/compute_user_data.sh.tftpl`

- [ ] **Step 1: Create the production Terraform and provider declarations**

Create `environments/prod/terraform.tf`:

```hcl
terraform {
  required_version = "~> 1.16.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {}
}
```

Create `environments/prod/providers.tf`:

```hcl
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}
```

Create `environments/prod/locals.tf`:

```hcl
locals {
  name_prefix = "${var.project_name}-prod"

  common_tags = {
    Project     = var.project_name
    Environment = "prod"
    ManagedBy   = "terraform"
    Repository  = "terraform-infrastructure-projects"
    Owner       = var.owner
  }
}
```

- [ ] **Step 2: Define production operator inputs and validations**

Create `environments/prod/variables.tf` with the same validated `project_name`,
`owner`, `aws_region`, `availability_zones`, and `/16` `vpc_cidr` declarations as
development, changing descriptions to production and setting `vpc_cidr` to
`10.20.0.0/16`. Add this required restricted-ingress input:

```hcl
variable "load_balancer_ingress_cidrs" {
  type        = set(string)
  description = "Restricted IPv4 CIDR blocks allowed to reach the production HTTP load balancer."

  validation {
    condition = (
      length(var.load_balancer_ingress_cidrs) > 0 &&
      !contains(var.load_balancer_ingress_cidrs, "0.0.0.0/0") &&
      alltrue([
        for cidr in var.load_balancer_ingress_cidrs :
        can(cidrnetmask(cidr))
      ])
    )
    error_message = "load_balancer_ingress_cidrs must contain valid restricted IPv4 CIDRs and must not include 0.0.0.0/0."
  }
}
```

- [ ] **Step 3: Wire the production modules with explicit safeguards**

Create `environments/prod/main.tf` by retaining the development module wiring and
application template inputs, with these production arguments:

```hcl
module "network" {
  source = "../../modules/network"

  name_prefix        = local.name_prefix
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  single_nat_gateway = false
  tags               = local.common_tags
}

module "security" {
  source = "../../modules/security"

  name_prefix                 = local.name_prefix
  vpc_id                      = module.network.vpc_id
  load_balancer_ingress_cidrs = var.load_balancer_ingress_cidrs
  enable_load_balancer_https  = false
  tags                        = local.common_tags
}

module "rds" {
  source = "../../modules/rds"

  name_prefix                = local.name_prefix
  database_subnet_ids_by_az  = module.network.database_subnet_ids_by_az
  database_security_group_id = module.security.database_security_group_id
  database_name              = "appdb"
  master_username            = "app_admin"
  engine_version             = "17"
  instance_class             = "db.t4g.small"
  allocated_storage          = 20
  storage_type               = "gp3"
  multi_az                   = true
  backup_retention_period    = 30
  deletion_protection        = true
  skip_final_snapshot        = false
  final_snapshot_identifier  = "${local.name_prefix}-postgresql-final"
  auto_minor_version_upgrade = true

  enabled_cloudwatch_logs_exports  = ["postgresql", "upgrade"]
  cloudwatch_log_retention_in_days = 30
  tags                             = local.common_tags
}
```

Retain the IAM and load-balancer blocks from development. Retain the compute block
and template input map, changing only these settings:

```hcl
  instance_type    = "t3.micro"
  min_size         = 2
  desired_capacity = 2
  max_size         = 4
```

- [ ] **Step 4: Add production outputs and the shared bootstrap template**

Copy the development outputs to `environments/prod/outputs.tf` and replace every
word `development` with `production`; resource references remain identical.
Copy `environments/dev/templates/compute_user_data.sh.tftpl` byte-for-byte to
`environments/prod/templates/compute_user_data.sh.tftpl` so the production root
has an environment-local, reviewable bootstrap artifact.

- [ ] **Step 5: Add non-secret production configuration examples**

Create `environments/prod/backend.hcl.example`:

```hcl
bucket       = "replace-with-state-bucket-name"
key          = "multi-environment-web-app/prod/terraform.tfstate"
region       = "us-east-1"
encrypt      = true
use_lockfile = true
```

Create `environments/prod/terraform.tfvars.example`:

```hcl
owner                        = "replace-with-owner"
aws_region                   = "us-east-1"
availability_zones           = ["us-east-1a", "us-east-1b"]
# Documentation-only range: replace it with approved client CIDRs before planning.
load_balancer_ingress_cidrs = ["203.0.113.0/24"]
```

- [ ] **Step 6: Initialize and validate the production root without a backend**

Run:

```bash
terraform fmt environments/prod
terraform -chdir=environments/prod init -backend=false
terraform -chdir=environments/prod validate
```

Expected: initialization succeeds and validation reports `Success! The configuration is valid.`

- [ ] **Step 7: Commit the production root**

```bash
git add multi-environment-web-app/environments/prod
git commit -m "feat(prod): add resilient production root"
```

### Task 3: Protect production invariants with Terraform tests

**Files:**
- Create: `environments/prod/tests/production.tftest.hcl`

- [ ] **Step 1: Add mocked-provider production contract tests**

Create `environments/prod/tests/production.tftest.hcl` with a mocked AWS provider,
the SSM AMI mock used by the compute tests, and valid production variables:

```hcl
mock_provider "aws" {
  mock_data "aws_ssm_parameter" {
    defaults = {
      value = "ami-0123456789abcdef0"
    }
  }
}

variables {
  owner                        = "platform-team"
  aws_region                   = "us-east-1"
  availability_zones          = ["us-east-1a", "us-east-1b"]
  load_balancer_ingress_cidrs = ["203.0.113.0/24"]
}

run "enforces_production_resilience" {
  command = plan

  assert {
    condition     = length(module.network.nat_gateway_public_ips) == 2
    error_message = "Production must create one NAT gateway per Availability Zone."
  }

  assert {
    condition     = module.rds.multi_az == true
    error_message = "Production RDS must use Multi-AZ."
  }

  assert {
    condition = (
      module.rds.deletion_protection == true &&
      module.rds.skip_final_snapshot == false &&
      module.rds.final_snapshot_identifier == "multi-environment-web-app-prod-postgresql-final" &&
      module.rds.backup_retention_period == 30
    )
    error_message = "Production RDS must enable deletion protection, retain 30 days of backups, and require the approved final snapshot."
  }

  assert {
    condition = (
      module.compute.min_size == 2 &&
      module.compute.desired_capacity == 2 &&
      module.compute.max_size == 4
    )
    error_message = "Production Auto Scaling capacity must be 2/2/4."
  }

  assert {
    condition     = length(module.compute.application_subnet_ids) == 2
    error_message = "Production compute must span both application subnets."
  }

  assert {
    condition = (
      module.security.http_ingress_rule_count == 1 &&
      module.security.https_ingress_rule_count == 0
    )
    error_message = "Production must allow approved HTTP CIDRs and must not expose unused HTTPS ingress."
  }
}

run "rejects_public_ingress" {
  command = plan

  variables {
    load_balancer_ingress_cidrs = ["0.0.0.0/0"]
  }

  expect_failures = [var.load_balancer_ingress_cidrs]
}
```

- [ ] **Step 2: Run tests and confirm the missing contract outputs fail clearly**

Run:

```bash
terraform -chdir=environments/prod test
```

Expected: FAIL because the new RDS, compute, and security contract outputs do not
exist. The mocked provider must prevent authentication and real AWS calls.

- [ ] **Step 3: Add exact non-sensitive module outputs for assertions**

Append to `modules/rds/outputs.tf`:

```hcl
output "multi_az" {
  description = "Whether the DB instance uses Multi-AZ deployment."
  value       = aws_db_instance.this.multi_az
}

output "deletion_protection" {
  description = "Whether deletion protection is enabled for the DB instance."
  value       = aws_db_instance.this.deletion_protection
}

output "skip_final_snapshot" {
  description = "Whether the DB instance skips a final snapshot during destruction."
  value       = aws_db_instance.this.skip_final_snapshot
}

output "final_snapshot_identifier" {
  description = "Identifier used for the DB instance final snapshot."
  value       = aws_db_instance.this.final_snapshot_identifier
}

output "backup_retention_period" {
  description = "Automated backup retention period for the DB instance."
  value       = aws_db_instance.this.backup_retention_period
}
```

Append to `modules/compute/outputs.tf`:

```hcl
output "min_size" {
  description = "Minimum Auto Scaling group capacity."
  value       = aws_autoscaling_group.this.min_size
}

output "desired_capacity" {
  description = "Desired Auto Scaling group capacity."
  value       = aws_autoscaling_group.this.desired_capacity
}

output "max_size" {
  description = "Maximum Auto Scaling group capacity."
  value       = aws_autoscaling_group.this.max_size
}

output "application_subnet_ids" {
  description = "Private application subnet IDs used by the Auto Scaling group."
  value       = aws_autoscaling_group.this.vpc_zone_identifier
}
```

Append to `modules/security/outputs.tf`:

```hcl
output "http_ingress_rule_count" {
  description = "Number of load-balancer HTTP ingress rules."
  value       = length(aws_vpc_security_group_ingress_rule.load_balancer_http)
}

output "https_ingress_rule_count" {
  description = "Number of load-balancer HTTPS ingress rules."
  value       = length(aws_vpc_security_group_ingress_rule.load_balancer_https)
}
```

These outputs expose configuration metadata only. Do not output credentials,
secret values, or user data.

- [ ] **Step 4: Run the production and affected module tests**

Run:

```bash
terraform fmt -recursive .
terraform -chdir=environments/prod test
terraform -chdir=modules/security test
terraform -chdir=modules/compute test
terraform -chdir=modules/load-balancer test
```

Expected: all runs PASS.

- [ ] **Step 5: Commit the production tests**

```bash
git add multi-environment-web-app/environments/prod/tests multi-environment-web-app/modules
git commit -m "test(prod): enforce production safeguards"
```

### Task 4: Document production operation and recovery

**Files:**
- Modify: `README.md`
- Modify: `docs/architecture.md`
- Modify: `docs/deployment.md`
- Modify: `docs/state-management.md`
- Modify: `docs/security.md`
- Modify: `docs/recovery.md`
- Modify: `docs/teardown.md`
- Modify: `docs/testing.md`

- [ ] **Step 1: Update repository status and layout**

Update `README.md` to list `environments/prod`, describe the Multi-AZ RDS, dual
NAT, 2/2/4 ASG, restricted HTTP ingress, and separate state. Remove statements
that production is unimplemented while preserving HTTPS/DNS limitations.

- [ ] **Step 2: Add a production planning procedure**

Add a production section to `docs/deployment.md` with these commands:

```bash
cd environments/prod
cp backend.hcl.example backend.hcl
cp terraform.tfvars.example terraform.tfvars
terraform init -backend-config=backend.hcl
terraform validate
terraform test
terraform plan -var-file=terraform.tfvars -out=prod.tfplan
terraform show -no-color prod.tfplan
```

State clearly that the example CIDR must be replaced, the identity/account must
be checked first, and this stage does not authorize `terraform apply`.

- [ ] **Step 3: Document state, security, recovery, and teardown behavior**

Record the production key as
`multi-environment-web-app/prod/terraform.tfstate`. Explain that production state
must never be initialized with the development key. Document CIDR-restricted HTTP,
disabled unused 443 ingress, same-AZ NAT routing, RDS Multi-AZ failover, deletion
protection, 30-day backups, and final snapshots. Explain that production teardown
requires a separately reviewed change disabling deletion protection and must not
skip the final snapshot.

- [ ] **Step 4: Update the validation matrix**

Add these commands to `docs/testing.md`:

```bash
terraform -chdir=environments/prod init -backend=false
terraform -chdir=environments/prod validate
terraform -chdir=environments/prod test
terraform -chdir=modules/security init -backend=false
terraform -chdir=modules/security test
```

Document the exact invariants covered by the production tests and distinguish
mocked tests from a credentialed speculative plan.

- [ ] **Step 5: Check documentation consistency and commit**

Run:

```bash
rg -n "production is not implemented|Only development is implemented|Production Safeguards Not Yet Implemented" README.md docs
git diff --check
```

Expected: the stale statements are absent and `git diff --check` is clean.

```bash
git add multi-environment-web-app/README.md multi-environment-web-app/docs
git commit -m "docs(prod): add production operations guidance"
```

### Task 5: Run the complete safe validation suite

**Files:**
- No source files expected

- [ ] **Step 1: Verify formatting and backend-free validation**

Run from `multi-environment-web-app`:

```bash
terraform fmt -check -recursive .
terraform -chdir=environments/dev init -backend=false
terraform -chdir=environments/dev validate
terraform -chdir=environments/prod init -backend=false
terraform -chdir=environments/prod validate
```

Expected: all commands exit 0.

- [ ] **Step 2: Run every Terraform test suite**

Run:

```bash
terraform -chdir=environments/prod test
terraform -chdir=modules/security test
terraform -chdir=modules/compute test
terraform -chdir=modules/load-balancer test
```

Expected: all test runs PASS without contacting AWS.

- [ ] **Step 3: Run the application tests**

Run:

```bash
application/.venv/bin/python -m pytest application
```

If the repository virtual environment does not exist, create it and install
`application/requirements-dev.txt` before rerunning. Expected: all tests PASS.

- [ ] **Step 4: Decide safely whether to run a speculative production plan**

Run only read-only checks first:

```bash
aws sts get-caller-identity
test -f environments/prod/backend.hcl
test -f environments/prod/terraform.tfvars
```

Run a speculative plan only when credentials are already valid, both ignored
local files exist, the backend key is exactly the production key, and the
variables contain approved non-public CIDRs:

```bash
terraform -chdir=environments/prod init -backend-config=backend.hcl
terraform -chdir=environments/prod plan -lock=false -refresh=false -var-file=terraform.tfvars
```

Expected: a create-only production plan or a documented reason for skipping it.
Never run `terraform apply`, never save or commit a plan artifact, and do not
mutate state.

- [ ] **Step 5: Review the final diff and status**

Run:

```bash
git diff --check
git status --short
git log --oneline -6
```

Expected: no uncommitted implementation changes, no ignored secrets or plan
files staged, and commits limited to the approved production stage.

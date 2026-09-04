# CloudWatch Observability Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add reusable CloudWatch log collection and five essential alarms to development and production without notification channels or dashboards.

**Architecture:** A focused `observability` module owns three log groups and the ALB, Auto Scaling, EC2 CPU, RDS CPU, and RDS storage alarms. Both environment roots pass deterministic ASG/RDS names and load-balancer suffixes to the module, scope the existing EC2 IAM policy to its log groups, and render an environment-local CloudWatch agent configuration into user data.

**Tech Stack:** Terraform 1.16, AWS provider 6.x, Amazon CloudWatch agent, Terraform test framework, pytest.

---

### Task 1: Build the reusable observability module

**Files:**
- Create: `modules/observability/terraform.tf`
- Create: `modules/observability/variables.tf`
- Create: `modules/observability/main.tf`
- Create: `modules/observability/outputs.tf`
- Create: `modules/observability/tests/observability.tftest.hcl`

- [ ] **Step 1: Write the failing module contract test**

Create `modules/observability/tests/observability.tftest.hcl` with a mocked AWS
provider and a `command = plan` run using these variables:

```hcl
mock_provider "aws" {}

variables {
  name_prefix                    = "example-prod"
  load_balancer_arn_suffix       = "app/example-prod/0123456789abcdef"
  target_group_arn_suffix        = "targetgroup/example-prod/0123456789abcdef"
  autoscaling_group_name         = "example-prod-application-asg"
  database_instance_identifier   = "example-prod-postgresql"
  minimum_healthy_instance_count = 2
  log_retention_in_days          = 30
  ec2_cpu_threshold_percent      = 80
  rds_cpu_threshold_percent      = 80
  rds_free_storage_threshold     = 5368709120
  tags = {
    Environment = "test"
  }
}
```

Assert that `aws_cloudwatch_log_group.this` has exactly the keys `application`,
`nginx`, and `cloud_init`, all with 30-day retention. Assert these exact metric
contracts:

```hcl
assert {
  condition = (
    aws_cloudwatch_metric_alarm.alb_unhealthy.namespace == "AWS/ApplicationELB" &&
    aws_cloudwatch_metric_alarm.alb_unhealthy.metric_name == "UnHealthyHostCount" &&
    aws_cloudwatch_metric_alarm.alb_unhealthy.dimensions.LoadBalancer == "app/example-prod/0123456789abcdef" &&
    aws_cloudwatch_metric_alarm.alb_unhealthy.dimensions.TargetGroup == "targetgroup/example-prod/0123456789abcdef" &&
    length(aws_cloudwatch_metric_alarm.alb_unhealthy.alarm_actions) == 0
  )
  error_message = "The ALB alarm must monitor unhealthy targets without actions."
}

assert {
  condition = (
    aws_cloudwatch_metric_alarm.asg_capacity.namespace == "AWS/AutoScaling" &&
    aws_cloudwatch_metric_alarm.asg_capacity.metric_name == "GroupInServiceInstances" &&
    aws_cloudwatch_metric_alarm.asg_capacity.threshold == 2 &&
    aws_cloudwatch_metric_alarm.asg_capacity.dimensions.AutoScalingGroupName == "example-prod-application-asg"
  )
  error_message = "The capacity alarm must enforce the environment minimum."
}
```

Add equivalent assertions for EC2 `CPUUtilization` aggregated by
`AutoScalingGroupName`, RDS `CPUUtilization`, and RDS `FreeStorageSpace`, using
the values above. Assert `treat_missing_data = "breaching"` for availability,
capacity, and storage and `treat_missing_data = "missing"` for both CPU alarms.

- [ ] **Step 2: Run the new test and verify it fails**

```bash
terraform -chdir=modules/observability init -backend=false
terraform -chdir=modules/observability test
```

Expected: FAIL because the module files and resources do not exist.

- [ ] **Step 3: Define the module provider and validated inputs**

Create `terraform.tf` with Terraform `>= 1.16.0, < 2.0.0` and AWS provider
`>= 6.0.0, < 7.0.0`. In `variables.tf`, declare the variables from Step 1 with
their exact types: strings for identifiers, number for counts and thresholds,
and `map(string)` for tags. Validate non-empty identifiers; require the minimum
count to be a positive integer; allow only CloudWatch-supported retention values;
require CPU thresholds in `(0, 100]`; and require the storage threshold to be a
positive integer.

- [ ] **Step 4: Create log groups and alarms**

In `main.tf`, define:

```hcl
locals {
  log_groups = {
    application = "/${var.name_prefix}/application"
    nginx       = "/${var.name_prefix}/nginx"
    cloud_init  = "/${var.name_prefix}/cloud-init"
  }
}

resource "aws_cloudwatch_log_group" "this" {
  for_each = local.log_groups

  name              = each.value
  retention_in_days = var.log_retention_in_days
  tags               = merge(var.tags, { Name = each.value })
}
```

Create five `aws_cloudwatch_metric_alarm` resources using these exact settings:

- `alb_unhealthy`: `AWS/ApplicationELB`, `UnHealthyHostCount`, `Maximum`, 60-second
  period, 2 evaluation periods, `GreaterThanThreshold`, threshold 0, dimensions
  `LoadBalancer` and `TargetGroup`, missing data `breaching`.
- `asg_capacity`: `AWS/AutoScaling`, `GroupInServiceInstances`, `Minimum`,
  60-second period, 2 evaluation periods, `LessThanThreshold`, threshold
  `minimum_healthy_instance_count`, dimension `AutoScalingGroupName`, missing data
  `breaching`.
- `ec2_cpu`: `AWS/EC2`, `CPUUtilization`, `Average`, 300-second period, 2
  evaluation periods, `GreaterThanThreshold`, threshold
  `ec2_cpu_threshold_percent`, dimension `AutoScalingGroupName`, missing data
  `missing`.
- `rds_cpu`: `AWS/RDS`, `CPUUtilization`, `Average`, 300-second period, 2
  evaluation periods, `GreaterThanThreshold`, threshold
  `rds_cpu_threshold_percent`, dimension `DBInstanceIdentifier`, missing data
  `missing`.
- `rds_free_storage`: `AWS/RDS`, `FreeStorageSpace`, `Minimum`, 300-second period,
  2 evaluation periods, `LessThanThreshold`, threshold
  `rds_free_storage_threshold`, dimension `DBInstanceIdentifier`, missing data
  `breaching`.

Set descriptive names from `name_prefix`, `actions_enabled = false`, and common
tags on every alarm. Do not set alarm, OK, or insufficient-data action ARNs.

- [ ] **Step 5: Add non-sensitive outputs**

Create `outputs.tf`:

```hcl
output "log_group_names" {
  description = "CloudWatch log-group names keyed by log source."
  value       = { for key, group in aws_cloudwatch_log_group.this : key => group.name }
}

output "log_group_arns" {
  description = "CloudWatch log-group ARNs keyed by log source."
  value       = { for key, group in aws_cloudwatch_log_group.this : key => group.arn }
}

output "alarm_names" {
  description = "Names of the essential CloudWatch alarms."
  value = {
    alb_unhealthy   = aws_cloudwatch_metric_alarm.alb_unhealthy.alarm_name
    asg_capacity    = aws_cloudwatch_metric_alarm.asg_capacity.alarm_name
    ec2_cpu         = aws_cloudwatch_metric_alarm.ec2_cpu.alarm_name
    rds_cpu         = aws_cloudwatch_metric_alarm.rds_cpu.alarm_name
    rds_free_storage = aws_cloudwatch_metric_alarm.rds_free_storage.alarm_name
  }
}
```

- [ ] **Step 6: Format, test, and commit the module**

```bash
terraform fmt -recursive modules/observability
terraform -chdir=modules/observability test
git add multi-environment-web-app/modules/observability
git commit -m "feat(observability): add CloudWatch monitoring module"
```

Expected: all observability test runs PASS.

### Task 2: Expose load-balancer metric identifiers

**Files:**
- Modify: `modules/load-balancer/outputs.tf`
- Modify: `modules/load-balancer/tests/load_balancer.tftest.hcl`

- [ ] **Step 1: Add failing output assertions**

Add plan-time mock defaults for `aws_lb.this.arn_suffix` and
`aws_lb_target_group.application.arn_suffix`, then assert:

```hcl
assert {
  condition     = output.arn_suffix == "app/example-dev/0123456789abcdef"
  error_message = "The module must expose the ALB ARN suffix for CloudWatch dimensions."
}

assert {
  condition     = output.target_group_arn_suffix == "targetgroup/example-dev/0123456789abcdef"
  error_message = "The module must expose the target-group ARN suffix for CloudWatch dimensions."
}
```

- [ ] **Step 2: Run the test and verify the outputs are absent**

```bash
terraform -chdir=modules/load-balancer test
```

Expected: FAIL with unsupported output attributes.

- [ ] **Step 3: Add the two outputs**

Append to `modules/load-balancer/outputs.tf`:

```hcl
output "arn_suffix" {
  description = "ARN suffix used by Application Load Balancer CloudWatch metrics."
  value       = aws_lb.this.arn_suffix
}

output "target_group_arn_suffix" {
  description = "ARN suffix used by target-group CloudWatch metrics."
  value       = aws_lb_target_group.application.arn_suffix
}
```

- [ ] **Step 4: Test and commit the interface**

```bash
terraform fmt modules/load-balancer
terraform -chdir=modules/load-balancer test
git add multi-environment-web-app/modules/load-balancer
git commit -m "feat(load-balancer): expose CloudWatch metric identifiers"
```

Expected: all load-balancer tests PASS.

### Task 3: Add CloudWatch agent bootstrap

**Files:**
- Modify: `environments/dev/templates/compute_user_data.sh.tftpl`
- Modify: `environments/prod/templates/compute_user_data.sh.tftpl`

- [ ] **Step 1: Extend both templates with a dedicated application log file**

Add these directives to the `[Service]` section of `snake-app.service`:

```ini
LogsDirectory=snake-app
StandardOutput=append:/var/log/snake-app/application.log
StandardError=append:/var/log/snake-app/application.log
```

- [ ] **Step 2: Install and configure the CloudWatch agent in both templates**

Add `amazon-cloudwatch-agent` to the existing `dnf install` command. Before
starting application services, write this JSON to
`/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json`:

```json
{
  "agent": { "region": "${aws_region}" },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          { "file_path": "/var/log/snake-app/application.log", "log_group_name": "${application_log_group_name}", "log_stream_name": "{instance_id}" },
          { "file_path": "/var/log/nginx/access.log", "log_group_name": "${nginx_log_group_name}", "log_stream_name": "{instance_id}/access" },
          { "file_path": "/var/log/nginx/error.log", "log_group_name": "${nginx_log_group_name}", "log_stream_name": "{instance_id}/error" },
          { "file_path": "/var/log/cloud-init-output.log", "log_group_name": "${cloud_init_log_group_name}", "log_stream_name": "{instance_id}" }
        ]
      }
    }
  }
}
```

Start it with:

```bash
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
```

- [ ] **Step 3: Verify the templates remain identical and commit**

```bash
cmp environments/dev/templates/compute_user_data.sh.tftpl environments/prod/templates/compute_user_data.sh.tftpl
git diff --check
git add multi-environment-web-app/environments/dev/templates multi-environment-web-app/environments/prod/templates
git commit -m "feat(compute): ship instance logs to CloudWatch"
```

Expected: `cmp` and `git diff --check` exit 0.

### Task 4: Integrate observability into both roots

**Files:**
- Modify: `environments/dev/main.tf`
- Modify: `environments/dev/outputs.tf`
- Modify: `environments/prod/main.tf`
- Modify: `environments/prod/outputs.tf`
- Modify: `environments/prod/tests/production.tftest.hcl`
- Create: `environments/dev/tests/observability.tftest.hcl`

- [ ] **Step 1: Add the development root test**

Create a mocked-provider test using the existing production mock patterns. Assert
that development creates three 7-day log groups, sets minimum healthy instances
to 1, uses a 2 GiB RDS free-storage threshold, passes all three log-group names
into rendered user data, and scopes the IAM module to exactly three log-group
ARNs.

- [ ] **Step 2: Extend the production test**

Assert that production creates three 30-day log groups, uses minimum healthy
instances 2, uses a 5 GiB storage threshold, renders all three log-group names in
user data, and scopes IAM to exactly three log-group ARNs.

- [ ] **Step 3: Run both tests and verify they fail**

```bash
terraform -chdir=environments/dev test
terraform -chdir=environments/prod test
```

Expected: FAIL because neither root declares `module.observability` or the new
template variables.

- [ ] **Step 4: Add the module to development**

Add:

```hcl
module "observability" {
  source = "../../modules/observability"

  name_prefix                    = local.name_prefix
  load_balancer_arn_suffix       = module.load_balancer.arn_suffix
  target_group_arn_suffix        = module.load_balancer.target_group_arn_suffix
  autoscaling_group_name         = "${local.name_prefix}-application-asg"
  database_instance_identifier   = "${local.name_prefix}-postgresql"
  minimum_healthy_instance_count = 1
  log_retention_in_days          = 7
  ec2_cpu_threshold_percent      = 80
  rds_cpu_threshold_percent      = 80
  rds_free_storage_threshold     = 2147483648
  tags                           = local.common_tags
}
```

Pass `values(module.observability.log_group_arns)` to the IAM module. Add the
three log-group names to the template map using keys
`application_log_group_name`, `nginx_log_group_name`, and
`cloud_init_log_group_name`.

- [ ] **Step 5: Add the module to production**

Use the same block with `minimum_healthy_instance_count = 2`,
`log_retention_in_days = 30`, and
`rds_free_storage_threshold = 5368709120`. Apply the identical IAM and template
map wiring.

- [ ] **Step 6: Add root outputs**

In both root `outputs.tf` files, expose:

```hcl
output "cloudwatch_log_group_names" {
  description = "CloudWatch log groups used by this environment."
  value       = module.observability.log_group_names
}

output "cloudwatch_alarm_names" {
  description = "Essential CloudWatch alarms used by this environment."
  value       = module.observability.alarm_names
}
```

- [ ] **Step 7: Format, validate, test, and commit both roots**

```bash
terraform fmt -recursive environments
terraform -chdir=environments/dev init -backend=false
terraform -chdir=environments/dev validate
terraform -chdir=environments/dev test
terraform -chdir=environments/prod init -backend=false
terraform -chdir=environments/prod validate
terraform -chdir=environments/prod test
git add multi-environment-web-app/environments
git commit -m "feat(observability): enable monitoring in both environments"
```

Expected: both roots validate and all root tests PASS.

### Task 5: Update observability documentation

**Files:**
- Modify: `README.md`
- Modify: `docs/architecture.md`
- Modify: `docs/deployment.md`
- Modify: `docs/implementation-plan.md`
- Modify: `docs/recovery.md`
- Modify: `docs/security.md`
- Modify: `docs/testing.md`

- [ ] **Step 1: Document the implemented telemetry path**

Describe the three log sources, five alarms, 7-day development retention, 30-day
production retention, scoped EC2 write permissions, and absence of notifications
and dashboards.

- [ ] **Step 2: Add operator inspection commands**

Add these safe commands to `docs/deployment.md` and `docs/recovery.md`:

```bash
aws cloudwatch describe-alarms --alarm-name-prefix multi-environment-web-app-
aws logs describe-log-groups --log-group-name-prefix /multi-environment-web-app-
aws logs tail /multi-environment-web-app-dev/application --since 30m
```

Warn operators not to print secret values or full environment files into logs.

- [ ] **Step 3: Update testing and project status**

Record the observability module and root test commands, mark observability
implemented, and leave SNS, dashboards, custom metrics, and automated remediation
as explicit future work.

- [ ] **Step 4: Check and commit documentation**

```bash
rg -n "observability.*not configured|CloudWatch application/system log shipping and alarms are not configured" README.md docs
git diff --check
git add multi-environment-web-app/README.md multi-environment-web-app/docs
git commit -m "docs(observability): add CloudWatch operations guidance"
```

Expected: no stale statements and a clean whitespace check.

### Task 6: Run the complete safe validation suite

**Files:**
- No source files expected

- [ ] **Step 1: Run formatting and Terraform validation**

```bash
terraform fmt -check -recursive .
terraform -chdir=environments/dev validate
terraform -chdir=environments/prod validate
```

- [ ] **Step 2: Run all Terraform tests**

```bash
terraform -chdir=modules/observability test
terraform -chdir=modules/security test
terraform -chdir=modules/compute test
terraform -chdir=modules/load-balancer test
terraform -chdir=environments/dev test
terraform -chdir=environments/prod test
```

Expected: every run passes with mocked providers and no AWS resource creation.

- [ ] **Step 3: Run application tests**

```bash
cd application
.venv/bin/python -m pytest
```

Expected: 28 tests PASS.

- [ ] **Step 4: Evaluate speculative plans safely**

Run a speculative plan only for an environment whose ignored `backend.hcl` and
`terraform.tfvars` already exist, after verifying AWS identity and the exact
state key. Use `-lock=false -refresh=false`. Do not run `terraform apply`, save a
plan artifact, mutate state, or create AWS resources.

- [ ] **Step 5: Review final repository state**

```bash
git diff --check
git status --short
git log --oneline -8
```

Expected: clean status and commits limited to the approved observability stage.

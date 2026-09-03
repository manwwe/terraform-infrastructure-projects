# Application Load Balancer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Expose the development Snake application through a reusable internet-facing Application Load Balancer and attach its target group to the existing Auto Scaling group.

**Architecture:** A dedicated `load-balancer` module owns the ALB, HTTP target group, and port 80 listener. The development root places the ALB in both public subnets, forwards traffic to Nginx on private instances, and supplies the target group ARN to the compute module so Auto Scaling uses ELB health checks.

**Tech Stack:** Terraform 1.16, AWS provider 6.x, AWS Application Load Balancer, EC2 Auto Scaling, HTTP/Nginx/Flask

---

## File Map

- Create `modules/load-balancer/terraform.tf`: declare Terraform and AWS provider requirements.
- Create `modules/load-balancer/variables.tf`: define and validate the module interface.
- Create `modules/load-balancer/main.tf`: create the ALB, target group, health check, and HTTP listener.
- Create `modules/load-balancer/outputs.tf`: expose ALB and target-group identifiers.
- Create `modules/load-balancer/tests/load_balancer.tftest.hcl`: verify networking, routing, health checks, and validation with a mocked provider.
- Modify `environments/dev/main.tf`: instantiate the load-balancer module and attach its target group to compute.
- Modify `environments/dev/outputs.tf`: expose the public DNS name and load-balancer identifiers.

### Task 1: Define the Load Balancer Module Contract

**Files:**
- Create: `multi-environment-web-app/modules/load-balancer/terraform.tf`
- Create: `multi-environment-web-app/modules/load-balancer/variables.tf`

- [ ] **Step 1: Create the module test directory**

Run:

```bash
mkdir -p multi-environment-web-app/modules/load-balancer/tests
```

Expected: the command exits with status 0.

- [ ] **Step 2: Declare Terraform and provider requirements**

Write `multi-environment-web-app/modules/load-balancer/terraform.tf`:

```hcl
terraform {
  required_version = "~> 1.16.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0, < 7.0"
    }
  }
}
```

- [ ] **Step 3: Define validated module inputs**

Write `multi-environment-web-app/modules/load-balancer/variables.tf`:

```hcl
variable "name_prefix" {
  type        = string
  description = "Lowercase prefix used when naming load-balancing resources."

  validation {
    condition = (
      length(var.name_prefix) <= 64 &&
      !strcontains(var.name_prefix, "--") &&
      can(regex("^[a-z]([a-z0-9-]*[a-z0-9])?$", var.name_prefix))
    )
    error_message = "name_prefix must start with a lowercase letter, end with a lowercase letter or number, contain no consecutive hyphens, and contain at most 64 lowercase letters, numbers, or hyphens."
  }
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC containing the load balancer and target group."

  validation {
    condition     = can(regex("^vpc-[0-9a-f]+$", var.vpc_id))
    error_message = "vpc_id must be a valid VPC ID."
  }
}

variable "public_subnet_ids" {
  type        = set(string)
  description = "Public subnet IDs used by the internet-facing load balancer."

  validation {
    condition = (
      length(var.public_subnet_ids) >= 2 &&
      alltrue([
        for subnet_id in var.public_subnet_ids :
        can(regex("^subnet-[0-9a-f]+$", subnet_id))
      ])
    )
    error_message = "public_subnet_ids must contain at least two valid subnet IDs."
  }
}

variable "security_group_id" {
  type        = string
  description = "ID of the security group attached to the load balancer."

  validation {
    condition     = can(regex("^sg-[0-9a-f]+$", var.security_group_id))
    error_message = "security_group_id must be a valid security group ID."
  }
}

variable "application_port" {
  type        = number
  description = "Port used to reach Nginx on application instances."
  default     = 80

  validation {
    condition = (
      var.application_port >= 1 &&
      var.application_port <= 65535 &&
      floor(var.application_port) == var.application_port
    )
    error_message = "application_port must be an integer from 1 through 65535."
  }
}

variable "tags" {
  type        = map(string)
  description = "Additional tags applied to load-balancing resources."
  default     = {}
}
```

- [ ] **Step 4: Format and validate the contract**

Run:

```bash
terraform -chdir=multi-environment-web-app/modules/load-balancer fmt
terraform -chdir=multi-environment-web-app/modules/load-balancer init -backend=false
terraform -chdir=multi-environment-web-app/modules/load-balancer validate
```

Expected: initialization succeeds and validation reports `Success! The configuration is valid.`

- [ ] **Step 5: Commit the module contract**

```bash
git add multi-environment-web-app/modules/load-balancer/terraform.tf multi-environment-web-app/modules/load-balancer/variables.tf
git commit -m "feat(load-balancer): define module interface"
```

### Task 2: Specify and Implement Load Balancer Behavior

**Files:**
- Create: `multi-environment-web-app/modules/load-balancer/tests/load_balancer.tftest.hcl`
- Create: `multi-environment-web-app/modules/load-balancer/main.tf`
- Create: `multi-environment-web-app/modules/load-balancer/outputs.tf`

- [ ] **Step 1: Write mocked plan tests**

Write `multi-environment-web-app/modules/load-balancer/tests/load_balancer.tftest.hcl`:

```hcl
mock_provider "aws" {}

variables {
  name_prefix      = "example-dev"
  vpc_id           = "vpc-0123456789abcdef0"
  public_subnet_ids = [
    "subnet-0123456789abcdef0",
    "subnet-0fedcba9876543210",
  ]
  security_group_id = "sg-0123456789abcdef0"
  application_port  = 80
  tags = {
    Environment = "test"
  }
}

run "creates_public_application_load_balancer" {
  command = plan

  assert {
    condition     = aws_lb.this.internal == false
    error_message = "The application load balancer must be internet-facing."
  }

  assert {
    condition     = aws_lb.this.load_balancer_type == "application"
    error_message = "The load balancer must use the application type."
  }

  assert {
    condition = toset(aws_lb.this.subnets) == toset([
      "subnet-0123456789abcdef0",
      "subnet-0fedcba9876543210",
    ])
    error_message = "The load balancer must span all supplied public subnets."
  }

  assert {
    condition     = toset(aws_lb.this.security_groups) == toset(["sg-0123456789abcdef0"])
    error_message = "The load balancer must use the supplied security group."
  }

  assert {
    condition     = aws_lb.this.drop_invalid_header_fields == true
    error_message = "The load balancer must drop invalid HTTP header fields."
  }
}

run "forwards_http_to_healthy_instances" {
  command = plan

  assert {
    condition = (
      aws_lb_target_group.application.protocol == "HTTP" &&
      aws_lb_target_group.application.port == 80 &&
      aws_lb_target_group.application.target_type == "instance" &&
      aws_lb_target_group.application.vpc_id == "vpc-0123456789abcdef0"
    )
    error_message = "The target group must route HTTP port 80 to EC2 instances in the supplied VPC."
  }

  assert {
    condition = (
      aws_lb_target_group.application.health_check[0].path == "/health" &&
      aws_lb_target_group.application.health_check[0].matcher == "200" &&
      aws_lb_target_group.application.health_check[0].port == "traffic-port"
    )
    error_message = "The target group must require HTTP 200 from /health on the traffic port."
  }

  assert {
    condition = (
      aws_lb_listener.http.port == 80 &&
      aws_lb_listener.http.protocol == "HTTP" &&
      aws_lb_listener.http.default_action[0].type == "forward" &&
      aws_lb_listener.http.default_action[0].target_group_arn == aws_lb_target_group.application.arn
    )
    error_message = "The port 80 HTTP listener must forward to the application target group."
  }
}

run "rejects_insufficient_public_subnets" {
  command = plan

  variables {
    public_subnet_ids = ["subnet-0123456789abcdef0"]
  }

  expect_failures = [var.public_subnet_ids]
}

run "rejects_invalid_application_port" {
  command = plan

  variables {
    application_port = 70000
  }

  expect_failures = [var.application_port]
}
```

- [ ] **Step 2: Run the tests and verify they fail before resources exist**

Run:

```bash
terraform -chdir=multi-environment-web-app/modules/load-balancer test
```

Expected: tests fail because `aws_lb.this`, `aws_lb_target_group.application`, and `aws_lb_listener.http` do not exist.

- [ ] **Step 3: Implement the ALB, target group, listener, and health check**

Write `multi-environment-web-app/modules/load-balancer/main.tf`:

```hcl
locals {
  load_balancer_name = substr("${var.name_prefix}-alb", 0, 32)
  target_group_name  = substr("${var.name_prefix}-app", 0, 32)
}

resource "aws_lb" "this" {
  name                       = local.load_balancer_name
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [var.security_group_id]
  subnets                    = sort(tolist(var.public_subnet_ids))
  drop_invalid_header_fields = true

  tags = merge(var.tags, {
    Name = local.load_balancer_name
  })
}

resource "aws_lb_target_group" "application" {
  name                 = local.target_group_name
  port                 = var.application_port
  protocol             = "HTTP"
  target_type          = "instance"
  vpc_id               = var.vpc_id
  deregistration_delay = 30

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  tags = merge(var.tags, {
    Name = local.target_group_name
  })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.application.arn
  }

  tags = var.tags
}
```

- [ ] **Step 4: Expose module outputs**

Write `multi-environment-web-app/modules/load-balancer/outputs.tf`:

```hcl
output "arn" {
  description = "ARN of the application load balancer."
  value       = aws_lb.this.arn
}

output "dns_name" {
  description = "Public DNS name of the application load balancer."
  value       = aws_lb.this.dns_name
}

output "target_group_arn" {
  description = "ARN of the application target group."
  value       = aws_lb_target_group.application.arn
}

output "target_group_name" {
  description = "Name of the application target group."
  value       = aws_lb_target_group.application.name
}
```

- [ ] **Step 5: Format, validate, and run module tests**

Run:

```bash
terraform -chdir=multi-environment-web-app/modules/load-balancer fmt
terraform -chdir=multi-environment-web-app/modules/load-balancer validate
terraform -chdir=multi-environment-web-app/modules/load-balancer test
```

Expected: validation succeeds and all four test runs pass.

- [ ] **Step 6: Commit the tested module**

```bash
git add multi-environment-web-app/modules/load-balancer
git commit -m "feat(load-balancer): add HTTP application routing"
```

### Task 3: Wire the Load Balancer into Development

**Files:**
- Modify: `multi-environment-web-app/environments/dev/main.tf`
- Modify: `multi-environment-web-app/environments/dev/outputs.tf`

- [ ] **Step 1: Instantiate the load-balancer module before compute**

Add to `multi-environment-web-app/environments/dev/main.tf` before `module "compute"`:

```hcl
module "load_balancer" {
  source = "../../modules/load-balancer"

  name_prefix      = local.name_prefix
  vpc_id           = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  security_group_id = module.security.load_balancer_security_group_id
  application_port  = 80
  tags              = local.common_tags
}
```

- [ ] **Step 2: Attach the target group to the Auto Scaling group**

Add this argument to `module "compute"` in `multi-environment-web-app/environments/dev/main.tf`:

```hcl
  target_group_arns = [module.load_balancer.target_group_arn]
```

Expected: Terraform infers that the load balancer target group must exist before updating the Auto Scaling group.

- [ ] **Step 3: Expose development load-balancer outputs**

Append to `multi-environment-web-app/environments/dev/outputs.tf`:

```hcl
output "application_load_balancer_arn" {
  description = "ARN of the development application load balancer."
  value       = module.load_balancer.arn
}

output "application_load_balancer_dns_name" {
  description = "Public DNS name of the development application load balancer."
  value       = module.load_balancer.dns_name
}

output "application_target_group_arn" {
  description = "ARN of the development application target group."
  value       = module.load_balancer.target_group_arn
}

output "application_target_group_name" {
  description = "Name of the development application target group."
  value       = module.load_balancer.target_group_name
}
```

- [ ] **Step 4: Format and initialize the development root**

Run:

```bash
terraform -chdir=multi-environment-web-app/environments/dev fmt
terraform -chdir=multi-environment-web-app/environments/dev init -backend=false
terraform -chdir=multi-environment-web-app/environments/dev validate
```

Expected: initialization succeeds and validation reports `Success! The configuration is valid.`

- [ ] **Step 5: Run all Terraform module tests**

Run:

```bash
terraform -chdir=multi-environment-web-app/modules/network test
terraform -chdir=multi-environment-web-app/modules/security test
terraform -chdir=multi-environment-web-app/modules/iam test
terraform -chdir=multi-environment-web-app/modules/rds test
terraform -chdir=multi-environment-web-app/modules/compute test
terraform -chdir=multi-environment-web-app/modules/load-balancer test
```

Expected: every test run passes.

- [ ] **Step 6: Review a speculative development plan without applying it**

From `multi-environment-web-app/environments/dev`, initialize the existing remote backend and run:

```bash
terraform plan -var-file=terraform.tfvars -out=tfplan
terraform show -no-color tfplan
```

Expected: the plan creates one ALB, one target group, and one listener; updates the Auto Scaling group in place to attach the target group and use ELB health checks; and does not replace existing network, IAM, RDS, launch-template, or EC2 resources.

- [ ] **Step 7: Commit the development integration**

```bash
git add multi-environment-web-app/environments/dev/main.tf multi-environment-web-app/environments/dev/outputs.tf
git commit -m "feat(dev): expose application through load balancer"
```

### Task 4: Final Verification

**Files:**
- Verify: `multi-environment-web-app/modules/load-balancer/*.tf`
- Verify: `multi-environment-web-app/modules/load-balancer/tests/load_balancer.tftest.hcl`
- Verify: `multi-environment-web-app/environments/dev/main.tf`
- Verify: `multi-environment-web-app/environments/dev/outputs.tf`

- [ ] **Step 1: Check formatting and whitespace**

Run:

```bash
terraform fmt -check -recursive multi-environment-web-app
git diff --check
```

Expected: both commands exit with status 0.

- [ ] **Step 2: Confirm that no apply was performed**

Run:

```bash
git status --short
```

Expected: no Terraform state or plan file is staged; local ignored backend, variable, state, and plan files remain uncommitted.

- [ ] **Step 3: Summarize the handoff**

Report the new module, development wiring, test results, plan summary, and the future `application_load_balancer_dns_name` output. Explicitly state that `terraform apply` was not run.

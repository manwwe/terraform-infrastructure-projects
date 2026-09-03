# Compute Module Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and validate a reusable EC2 launch-template and Auto Scaling module, then wire it into development with a temporary Nginx health page.

**Architecture:** The module resolves the latest x86_64 Amazon Linux 2023 AMI, creates a hardened launch template, and runs it through an Auto Scaling group spanning the private application subnets. The development root supplies application-agnostic user data and existing network, security, and IAM outputs; the Snake application replaces the temporary bootstrap in a separate follow-up plan.

**Tech Stack:** Terraform 1.16, AWS provider 6.x, Amazon EC2, EC2 Auto Scaling, AWS Systems Manager Parameter Store, Amazon Linux 2023, Nginx

---

## File Map

- Create `modules/compute/terraform.tf`: declare Terraform and AWS provider requirements.
- Create `modules/compute/variables.tf`: define and validate the compute module contract.
- Create `modules/compute/main.tf`: look up the AMI and create the launch template and Auto Scaling group.
- Create `modules/compute/outputs.tf`: expose the launch template ID and Auto Scaling group identifiers.
- Create `modules/compute/tests/compute.tftest.hcl`: test security settings, placement, health-check selection, and capacity validation without creating AWS resources.
- Create `environments/dev/templates/compute_user_data.sh.tftpl`: install Nginx and expose a temporary health page.
- Modify `environments/dev/main.tf`: instantiate the compute module.
- Modify `environments/dev/outputs.tf`: expose development compute identifiers.

### Task 1: Define the Compute Module Contract

**Files:**
- Create: `multi-environment-web-app/modules/compute/terraform.tf`
- Create: `multi-environment-web-app/modules/compute/variables.tf`

- [ ] **Step 1: Create the module directory**

Run:

```bash
mkdir -p multi-environment-web-app/modules/compute/tests
```

Expected: the command exits with status 0.

- [ ] **Step 2: Declare Terraform and provider requirements**

Write `multi-environment-web-app/modules/compute/terraform.tf`:

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

- [ ] **Step 3: Define the module inputs**

Write `multi-environment-web-app/modules/compute/variables.tf`:

```hcl
variable "name_prefix" {
  type        = string
  description = "Lowercase prefix used when naming compute resources."

  validation {
    condition = (
      length(var.name_prefix) <= 64 &&
      !strcontains(var.name_prefix, "--") &&
      can(regex("^[a-z]([a-z0-9-]*[a-z0-9])?$", var.name_prefix))
    )
    error_message = "name_prefix must start with a lowercase letter, end with a lowercase letter or number, contain no consecutive hyphens, and contain at most 64 lowercase letters, numbers, or hyphens."
  }
}

variable "application_subnet_ids" {
  type        = set(string)
  description = "Private application subnet IDs used by the Auto Scaling group."

  validation {
    condition = (
      length(var.application_subnet_ids) >= 2 &&
      alltrue([
        for subnet_id in var.application_subnet_ids :
        can(regex("^subnet-[0-9a-f]+$", subnet_id))
      ])
    )
    error_message = "application_subnet_ids must contain at least two valid subnet IDs."
  }
}

variable "application_security_group_id" {
  type        = string
  description = "ID of the security group attached to application instances."

  validation {
    condition     = can(regex("^sg-[0-9a-f]+$", var.application_security_group_id))
    error_message = "application_security_group_id must be a valid security group ID."
  }
}

variable "instance_profile_name" {
  type        = string
  description = "Name of the IAM instance profile attached to application instances."

  validation {
    condition     = length(trimspace(var.instance_profile_name)) > 0
    error_message = "instance_profile_name must not be empty."
  }
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type used by the Auto Scaling group."

  validation {
    condition     = can(regex("^[a-z][a-z0-9]*\\.[a-z0-9]+$", var.instance_type))
    error_message = "instance_type must be a valid EC2 instance type such as t3.micro."
  }
}

variable "min_size" {
  type        = number
  description = "Minimum number of instances in the Auto Scaling group."

  validation {
    condition     = var.min_size >= 0 && floor(var.min_size) == var.min_size
    error_message = "min_size must be a non-negative integer."
  }
}

variable "desired_capacity" {
  type        = number
  description = "Desired number of instances in the Auto Scaling group."

  validation {
    condition     = var.desired_capacity >= 0 && floor(var.desired_capacity) == var.desired_capacity
    error_message = "desired_capacity must be a non-negative integer."
  }
}

variable "max_size" {
  type        = number
  description = "Maximum number of instances in the Auto Scaling group."

  validation {
    condition     = var.max_size >= 0 && floor(var.max_size) == var.max_size
    error_message = "max_size must be a non-negative integer."
  }
}

variable "user_data" {
  type        = string
  description = "Plain-text instance bootstrap script. It must not contain secret values."

  validation {
    condition     = startswith(trimspace(var.user_data), "#!")
    error_message = "user_data must be a non-empty script beginning with a shebang."
  }
}

variable "target_group_arns" {
  type        = set(string)
  description = "Load-balancer target group ARNs attached to the Auto Scaling group."
  default     = []

  validation {
    condition = alltrue([
      for arn in var.target_group_arns :
      can(regex("^arn:[^:]+:elasticloadbalancing:[^:]+:[0-9]{12}:targetgroup/.+$", arn))
    ])
    error_message = "target_group_arns must contain valid load-balancer target group ARNs."
  }
}

variable "tags" {
  type        = map(string)
  description = "Additional tags applied to compute resources."
  default     = {}
}
```

- [ ] **Step 4: Format and initialize the module**

Run:

```bash
terraform -chdir=multi-environment-web-app/modules/compute fmt
terraform -chdir=multi-environment-web-app/modules/compute init -backend=false
terraform -chdir=multi-environment-web-app/modules/compute validate
```

Expected: initialization succeeds and validation reports `Success! The configuration is valid.`

- [ ] **Step 5: Commit the contract**

```bash
git add multi-environment-web-app/modules/compute/terraform.tf multi-environment-web-app/modules/compute/variables.tf
git commit -m "feat(compute): define module interface"
```

### Task 2: Specify the Compute Resource Behavior

**Files:**
- Create: `multi-environment-web-app/modules/compute/tests/compute.tftest.hcl`

- [ ] **Step 1: Write plan-based module tests before the resources exist**

Write `multi-environment-web-app/modules/compute/tests/compute.tftest.hcl`:

```hcl
mock_provider "aws" {
  mock_data "aws_ssm_parameter" {
    defaults = {
      value = "ami-0123456789abcdef0"
    }
  }
}

variables {
  name_prefix                  = "example-dev"
  application_subnet_ids      = ["subnet-0123456789abcdef0", "subnet-0fedcba9876543210"]
  application_security_group_id = "sg-0123456789abcdef0"
  instance_profile_name       = "example-dev-application-profile"
  instance_type               = "t3.micro"
  min_size                    = 1
  desired_capacity            = 1
  max_size                    = 2
  user_data                   = "#!/bin/bash\necho ready"
  tags = {
    Environment = "test"
  }
}

run "creates_private_hardened_compute" {
  command = plan

  assert {
    condition     = aws_launch_template.this.image_id == "ami-0123456789abcdef0"
    error_message = "The launch template must use the AMI returned by the SSM parameter."
  }

  assert {
    condition     = aws_launch_template.this.metadata_options[0].http_tokens == "required"
    error_message = "The launch template must require IMDSv2 tokens."
  }

  assert {
    condition     = aws_launch_template.this.network_interfaces[0].associate_public_ip_address == false
    error_message = "Application instances must not receive public IP addresses."
  }

  assert {
    condition     = aws_launch_template.this.block_device_mappings[0].ebs[0].encrypted == true
    error_message = "The root EBS volume must be encrypted."
  }

  assert {
    condition     = aws_autoscaling_group.this.health_check_type == "EC2"
    error_message = "The group must use EC2 health checks before a target group is attached."
  }
}

run "uses_elb_health_checks_with_target_group" {
  command = plan

  variables {
    target_group_arns = [
      "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/example/0123456789abcdef"
    ]
  }

  assert {
    condition     = aws_autoscaling_group.this.health_check_type == "ELB"
    error_message = "The group must use ELB health checks when a target group is attached."
  }
}

run "rejects_invalid_capacity_order" {
  command = plan

  variables {
    min_size         = 2
    desired_capacity = 1
    max_size         = 3
  }

  expect_failures = [aws_autoscaling_group.this]
}
```

- [ ] **Step 2: Run the tests and confirm that they fail**

Run:

```bash
terraform -chdir=multi-environment-web-app/modules/compute test
```

Expected: the test run fails because `aws_launch_template.this` and `aws_autoscaling_group.this` do not exist yet.

- [ ] **Step 3: Commit the executable specification**

```bash
git add multi-environment-web-app/modules/compute/tests/compute.tftest.hcl
git commit -m "test(compute): specify launch and scaling behavior"
```

### Task 3: Implement the Launch Template and Auto Scaling Group

**Files:**
- Create: `multi-environment-web-app/modules/compute/main.tf`
- Create: `multi-environment-web-app/modules/compute/outputs.tf`

- [ ] **Step 1: Implement the resources**

Write `multi-environment-web-app/modules/compute/main.tf`:

```hcl
data "aws_ssm_parameter" "amazon_linux_2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

locals {
  instance_tags = merge(var.tags, {
    Name = "${var.name_prefix}-application"
    Tier = "application"
  })
}

resource "aws_launch_template" "this" {
  name_prefix            = "${var.name_prefix}-application-"
  description            = "Launch template for ${var.name_prefix} application instances."
  image_id               = data.aws_ssm_parameter.amazon_linux_2023_ami.value
  instance_type          = var.instance_type
  update_default_version = true
  user_data              = base64encode(var.user_data)

  iam_instance_profile {
    name = var.instance_profile_name
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_protocol_ipv6          = "disabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "required"
    instance_metadata_tags      = "disabled"
  }

  network_interfaces {
    associate_public_ip_address = false
    delete_on_termination       = true
    device_index                = 0
    security_groups             = [var.application_security_group_id]
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      delete_on_termination = true
      encrypted             = true
      volume_size           = 8
      volume_type           = "gp3"
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = local.instance_tags
  }

  tag_specifications {
    resource_type = "volume"
    tags          = local.instance_tags
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-application-launch-template"
  })
}

resource "aws_autoscaling_group" "this" {
  name = "${var.name_prefix}-application-asg"

  min_size         = var.min_size
  desired_capacity = var.desired_capacity
  max_size         = var.max_size

  vpc_zone_identifier = sort(tolist(var.application_subnet_ids))
  target_group_arns   = sort(tolist(var.target_group_arns))

  health_check_type         = length(var.target_group_arns) > 0 ? "ELB" : "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.this.id
    version = aws_launch_template.this.latest_version
  }

  instance_refresh {
    strategy = "Rolling"

    preferences {
      auto_rollback          = true
      max_healthy_percentage = 200
      min_healthy_percentage = 100
      skip_matching          = true
    }
  }

  dynamic "tag" {
    for_each = local.instance_tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    precondition {
      condition = (
        var.min_size <= var.desired_capacity &&
        var.desired_capacity <= var.max_size
      )
      error_message = "Capacity must satisfy min_size <= desired_capacity <= max_size."
    }
  }
}
```

- [ ] **Step 2: Add focused outputs**

Write `multi-environment-web-app/modules/compute/outputs.tf`:

```hcl
output "launch_template_id" {
  description = "ID of the application EC2 launch template."
  value       = aws_launch_template.this.id
}

output "autoscaling_group_name" {
  description = "Name of the application Auto Scaling group."
  value       = aws_autoscaling_group.this.name
}

output "autoscaling_group_arn" {
  description = "ARN of the application Auto Scaling group."
  value       = aws_autoscaling_group.this.arn
}
```

- [ ] **Step 3: Format and validate**

Run:

```bash
terraform -chdir=multi-environment-web-app/modules/compute fmt -check
terraform -chdir=multi-environment-web-app/modules/compute validate
```

Expected: both commands succeed.

- [ ] **Step 4: Run the module tests**

Run:

```bash
terraform -chdir=multi-environment-web-app/modules/compute test
```

Expected: all three runs pass, including the expected capacity failure.

- [ ] **Step 5: Commit the resources**

```bash
git add multi-environment-web-app/modules/compute/main.tf multi-environment-web-app/modules/compute/outputs.tf
git commit -m "feat(compute): add launch template and autoscaling group"
```

### Task 4: Wire Development with Temporary User Data

**Files:**
- Create: `multi-environment-web-app/environments/dev/templates/compute_user_data.sh.tftpl`
- Modify: `multi-environment-web-app/environments/dev/main.tf`
- Modify: `multi-environment-web-app/environments/dev/outputs.tf`

- [ ] **Step 1: Add a temporary, secret-free bootstrap script**

Write `multi-environment-web-app/environments/dev/templates/compute_user_data.sh.tftpl`:

```bash
#!/bin/bash
set -euo pipefail

dnf install -y nginx

cat > /usr/share/nginx/html/index.html <<'HTML'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Compute ready</title>
  </head>
  <body>
    <h1>Compute layer ready</h1>
  </body>
</html>
HTML

cat > /usr/share/nginx/html/health <<'TEXT'
healthy
TEXT

systemctl enable --now nginx
```

- [ ] **Step 2: Instantiate the module**

Append to `multi-environment-web-app/environments/dev/main.tf`:

```hcl
module "compute" {
  source = "../../modules/compute"

  name_prefix                  = local.name_prefix
  application_subnet_ids      = module.network.application_subnet_ids
  application_security_group_id = module.security.application_security_group_id
  instance_profile_name       = module.iam.instance_profile_name

  instance_type    = "t3.micro"
  min_size         = 1
  desired_capacity = 1
  max_size         = 2

  user_data = templatefile(
    "${path.module}/templates/compute_user_data.sh.tftpl",
    {}
  )

  tags = local.common_tags
}
```

- [ ] **Step 3: Export the compute identifiers**

Append to `multi-environment-web-app/environments/dev/outputs.tf`:

```hcl
output "application_launch_template_id" {
  description = "ID of the development application launch template."
  value       = module.compute.launch_template_id
}

output "application_autoscaling_group_name" {
  description = "Name of the development application Auto Scaling group."
  value       = module.compute.autoscaling_group_name
}

output "application_autoscaling_group_arn" {
  description = "ARN of the development application Auto Scaling group."
  value       = module.compute.autoscaling_group_arn
}
```

- [ ] **Step 4: Format and validate the development root**

Run:

```bash
terraform -chdir=multi-environment-web-app/environments/dev fmt -recursive
terraform -chdir=multi-environment-web-app/environments/dev init -backend=false
terraform -chdir=multi-environment-web-app/environments/dev validate
```

Expected: formatting passes and validation reports `Success! The configuration is valid.`

- [ ] **Step 5: Review a saved development plan**

Use the existing ignored `terraform.tfvars` from the earlier milestones, then run:

```bash
terraform -chdir=multi-environment-web-app/environments/dev plan -out=tfplan
terraform -chdir=multi-environment-web-app/environments/dev show tfplan
```

Expected: the plan creates one launch template and one Auto Scaling group with one
desired private instance. Confirm that it attaches the existing application
security group and instance profile, selects both application subnets, requires
IMDSv2, encrypts the root volume, and does not create an Elastic IP, SSH key, or
new IAM role.

- [ ] **Step 6: Remove the local plan artifact and commit the wiring**

Run:

```bash
rm multi-environment-web-app/environments/dev/tfplan
git add multi-environment-web-app/environments/dev/main.tf multi-environment-web-app/environments/dev/outputs.tf multi-environment-web-app/environments/dev/templates/compute_user_data.sh.tftpl
git commit -m "feat(dev): add private autoscaled compute"
```

### Task 5: Deploy and Verify the Compute Lifecycle

**Files:**
- Modify: `multi-environment-web-app/docs/testing.md`

- [ ] **Step 1: Apply the reviewed development plan**

Run a fresh plan and apply it according to the repository's established remote
backend workflow:

```bash
terraform -chdir=multi-environment-web-app/environments/dev plan -out=tfplan
terraform -chdir=multi-environment-web-app/environments/dev apply tfplan
```

Expected: the Auto Scaling group reaches a desired capacity of one.

- [ ] **Step 2: Verify private placement and Systems Manager registration**

Run:

```bash
asg_name=$(terraform -chdir=multi-environment-web-app/environments/dev output -raw application_autoscaling_group_name)
instance_id=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "$asg_name" --query 'AutoScalingGroups[0].Instances[0].InstanceId' --output text)
aws ec2 describe-instances --instance-ids "$instance_id" --query 'Reservations[0].Instances[0].{SubnetId:SubnetId,PublicIpAddress:PublicIpAddress}'
aws ssm describe-instance-information --filters "Key=InstanceIds,Values=$instance_id" --query 'InstanceInformationList[0].PingStatus' --output text
```

Expected: the instance is in one of the private application subnets,
`PublicIpAddress` is absent, and Systems Manager reports `PingStatus` as `Online`.

- [ ] **Step 3: Verify the bootstrap through Systems Manager**

Send a non-interactive Systems Manager command:

```bash
command_id=$(aws ssm send-command --instance-ids "$instance_id" --document-name AWS-RunShellScript --parameters 'commands=["systemctl is-active nginx","curl --fail http://localhost/health"]' --query 'Command.CommandId' --output text)
aws ssm wait command-executed --command-id "$command_id" --instance-id "$instance_id"
aws ssm get-command-invocation --command-id "$command_id" --instance-id "$instance_id" --query '{Status:Status,Output:StandardOutputContent}'
```

Expected: Nginx reports `active` and curl returns `healthy`.

- [ ] **Step 4: Verify automatic replacement**

Run:

```bash
aws ec2 terminate-instances --instance-ids "$instance_id"
aws autoscaling wait group-in-service --auto-scaling-group-names "$asg_name"
replacement_id=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "$asg_name" --query 'AutoScalingGroups[0].Instances[0].InstanceId' --output text)
test "$replacement_id" != "$instance_id"
```

Expected: the group launches a replacement, the replacement registers with
Systems Manager, and its local health endpoint returns `healthy`.

- [ ] **Step 5: Record the verified behavior**

Add a short `Compute Milestone` subsection to
`multi-environment-web-app/docs/testing.md` recording the date, environment,
private placement, Systems Manager registration, Nginx health result, and instance
replacement result. Do not record account IDs, instance IDs, IP addresses, or
secret values.

- [ ] **Step 6: Destroy temporary AWS resources and commit the evidence**

Run:

```bash
terraform -chdir=multi-environment-web-app/environments/dev destroy
git add multi-environment-web-app/docs/testing.md
git commit -m "docs(compute): record lifecycle validation"
```

Expected: Terraform reports that destruction completed and the remote state
contains no managed resources. The next implementation plan will replace the
temporary Nginx page with the Flask Snake application and database-backed scores.

# Development Deployment

## Prerequisites

Install Terraform `~> 1.16.0` and AWS CLI v2. Authenticate to the intended AWS
account and verify the caller before creating resources:

```bash
aws sts get-caller-identity
terraform version
```

Run commands from the `multi-environment-web-app` directory unless a step changes
directories. Local `backend.hcl` and `terraform.tfvars` files are intentionally
ignored by Git.

## Bootstrap Remote State

The bootstrap root creates the encrypted, versioned S3 state bucket. Do this once
per AWS account and Region.

```bash
cd bootstrap
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform validate
terraform plan -var-file=terraform.tfvars -out=tfplan
terraform show -no-color tfplan
```

Edit the local variables before planning. Apply only the reviewed saved plan:

```bash
terraform apply tfplan
```

Follow [the bootstrap guide](../bootstrap/README.md) to create `backend.hcl` and
migrate bootstrap state after the bucket exists. Do not guess the bucket name or
commit local backend configuration.

## Configure Development

```bash
cd ../environments/dev
cp backend.hcl.example backend.hcl
cp terraform.tfvars.example terraform.tfvars
```

Set the state bucket in `backend.hcl`, then set the owner and two supported
Availability Zones in `terraform.tfvars`. These files must remain uncommitted.

## Validate and Test

```bash
terraform init -backend-config=backend.hcl
terraform validate
terraform fmt -check -recursive ../..

terraform -chdir=../../modules/compute init -backend=false
terraform -chdir=../../modules/compute test
terraform -chdir=../../modules/load-balancer init -backend=false
terraform -chdir=../../modules/load-balancer test
```

Run application tests separately:

```bash
cd ../../application
python -m venv .venv
. .venv/bin/activate
python -m pip install -r requirements-dev.txt
python -m pytest
cd ../environments/dev
```

## Plan and Apply

Create a new saved plan immediately before deployment:

```bash
terraform plan -var-file=terraform.tfvars -out=tfplan
terraform show -no-color tfplan
```

Check every create, update, replacement, and deletion. A saved plan is tied to the
configuration and state at the time it was created; regenerate it after either
changes. Apply only the reviewed plan:

```bash
terraform apply tfplan
```

## Verify

Print the public development URL and check application/database health:

```bash
application_url="http://$(terraform output -raw application_load_balancer_dns_name)"
echo "$application_url"
curl --fail --silent --show-error "$application_url/health"
```

The health response should be `{"status":"healthy"}`. Open the URL, play Snake,
submit a score, and refresh the page to confirm the score persists.

Verify AWS routing and instance management without retrieving secret values:

```bash
aws elbv2 describe-target-health \
  --target-group-arn "$(terraform output -raw application_target_group_arn)"

aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names \
  "$(terraform output -raw application_autoscaling_group_name)"

aws ssm describe-instance-information
```

The target should become healthy, the Auto Scaling group should meet desired
capacity, and its instance should appear online in Systems Manager.

Inspect development alarms and log delivery without retrieving secret values:

```bash
aws cloudwatch describe-alarms \
  --alarm-name-prefix multi-environment-web-app-dev-
aws logs describe-log-groups \
  --log-group-name-prefix /multi-environment-web-app-dev/
aws logs tail /multi-environment-web-app-dev/application --since 30m
```

The environment also publishes Nginx and cloud-init logs. Do not print the
application environment file or Secrets Manager values into logs.

## Deploy Production

Verify the intended AWS account before initializing production:

```bash
aws sts get-caller-identity
cd ../prod
cp backend.hcl.example backend.hcl
cp terraform.tfvars.example terraform.tfvars
```

Set the existing state bucket in `backend.hcl`. Confirm that its key is exactly
`multi-environment-web-app/prod/terraform.tfstate`; never initialize production
with the development key. Replace the documentation-only ingress CIDR in
`terraform.tfvars` with approved client CIDRs.

```bash
terraform init -backend-config=backend.hcl
terraform validate
terraform test
terraform plan -var-file=terraform.tfvars -out=tfplan
terraform show -no-color tfplan
```

The review must confirm two NAT gateways, Multi-AZ RDS, deletion protection, a
required final snapshot, 30-day backup retention, two desired EC2 instances, a
maximum of four, and restricted HTTP ingress. Apply only the reviewed saved plan:

```bash
terraform apply tfplan
```

Do not commit `backend.hcl`, `terraform.tfvars`, or plan files.

For production inspection, use the alarm prefix
`multi-environment-web-app-prod-` and log-group prefix
`/multi-environment-web-app-prod/`.

## Deployment Record

As of September 4, 2026 UTC, the development environment was destroyed and the
production environment was deployed and verified in AWS account `924594387630`,
Region `us-east-1`.

Key production outputs:

```text
application_load_balancer_dns_name = "multi-environment-web-app-prod-a-1859276092.us-east-1.elb.amazonaws.com"
database_instance_identifier      = "multi-environment-web-app-prod-postgresql"
database_master_user_secret_arn   = "arn:aws:secretsmanager:us-east-1:924594387630:secret:rds!db-28dc0b96-28bd-4f7c-9278-2f5eb2bba355-WjSs69"
```

Verification results:

```text
Dev destroy: 56 destroyed; dev state list returned no resources.
Prod apply: 58 added, 0 changed, 0 destroyed.
Prod health: HTTP 200 with {"status":"healthy"}.
Prod drift check: No changes.
Prod CloudWatch alarms: 5 OK, 0 in alarm, 0 insufficient data.
```

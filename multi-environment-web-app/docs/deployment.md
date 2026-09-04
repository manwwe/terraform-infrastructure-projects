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

## Plan Production Without Applying

The production root is a validated configuration, not an authorization to create
resources. Verify the intended AWS account before initializing it:

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
terraform plan -var-file=terraform.tfvars -out=prod.tfplan
terraform show -no-color prod.tfplan
```

The review must confirm two NAT gateways, Multi-AZ RDS, deletion protection, a
required final snapshot, 30-day backup retention, two desired EC2 instances, a
maximum of four, and restricted HTTP ingress. Do not run `terraform apply` for
this stage, and do not commit `backend.hcl`, `terraform.tfvars`, or plan files.

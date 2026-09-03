# Testing Strategy

## Implemented Automated Checks

The application has 28 Python tests covering routes, score validation, database
behavior, retries, and secret handling. The compute module has 6 Terraform test
runs, and the load-balancer module has 4 Terraform test runs.

From the project directory, run:

```bash
terraform fmt -check -recursive .
terraform -chdir=environments/dev init -backend=false
terraform -chdir=environments/dev validate
terraform -chdir=modules/compute init -backend=false
terraform -chdir=modules/compute test
terraform -chdir=modules/load-balancer init -backend=false
terraform -chdir=modules/load-balancer test
```

Run the application suite in an isolated environment:

```bash
cd application
python -m venv .venv
. .venv/bin/activate
python -m pip install -r requirements-dev.txt
python -m pytest
```

## Plan Review

Development plans must be saved and inspected before use:

```bash
terraform plan -var-file=terraform.tfvars -out=tfplan
terraform show -no-color tfplan
```

Review for unexpected replacement or deletion, changes to public exposure,
private subnet placement, encryption, IAM scope, and environment-specific cost
settings.

## Deployment Verification

After deployment:

- Open the ALB HTTP URL and play the game.
- Confirm `/health` returns HTTP 200 and `{"status":"healthy"}`.
- Submit a score and confirm it remains on the leaderboard after refresh.
- Confirm the target is healthy in its ALB target group.
- Confirm the EC2 instance is online in Systems Manager.
- Confirm the Auto Scaling group reports its desired instance as healthy.

## Remaining Test Work

- Terraform tests for network, security, IAM, and RDS modules
- TFLint and Terraform security scanning
- CI automation
- Auto Scaling instance-replacement testing
- Production plans and safeguards, after production is implemented
- CloudWatch log and alarm verification, after observability is implemented

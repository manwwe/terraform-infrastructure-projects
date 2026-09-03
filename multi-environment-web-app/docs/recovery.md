# Development Recovery

Start with read-only checks. Do not apply a new plan, force-unlock state, untaint a
resource, or replace an instance until its actual AWS and Terraform states are
understood.

## Failed Apply but Auto Scaling Later Recovers

An initial Auto Scaling launch can fail while AWS finishes creating or propagating
its service-linked role. Auto Scaling may retry and successfully launch an
instance even though Terraform has already returned an error.

Inspect the group and recent scaling activities:

```bash
asg_name="$(terraform output -raw application_autoscaling_group_name)"
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "$asg_name"
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name "$asg_name" \
  --max-items 10
```

If the group exists, desired capacity is satisfied, and its instance is healthy,
run a fresh Terraform plan. A failed create may have marked the resource as
tainted even after AWS recovered:

```bash
terraform plan -var-file=terraform.tfvars
```

Use `terraform untaint module.compute.aws_autoscaling_group.this` only when the
real group exists, matches the configuration, and the sole proposed action is an
unnecessary replacement caused by taint. Then create and inspect a new saved
plan. Never reuse the failed apply's old plan.

## Unhealthy Load Balancer Target

Inspect the target reason first:

```bash
aws elbv2 describe-target-health \
  --target-group-arn "$(terraform output -raw application_target_group_arn)"
```

Confirm that the ALB security group can reach the application security group on
port 80 and that the application group accepts that referenced source. Then use
Systems Manager Run Command or Session Manager to check the instance without SSH:

```bash
cloud-init status --wait
systemctl status snake-app --no-pager
systemctl status nginx --no-pager
curl --fail --silent --show-error http://localhost/health
journalctl -u snake-app -n 100 --no-pager
tail -n 100 /var/log/cloud-init-output.log
```

Do not restart services until their failure output has been captured.

## Application or Database Failure

Check RDS status without displaying credentials:

```bash
aws rds describe-db-instances \
  --db-instance-identifier \
  "$(terraform output -raw database_instance_identifier)" \
  --query 'DBInstances[0].DBInstanceStatus' \
  --output text
```

On the instance, inspect `snake-app` logs and the local `/health` response. Confirm
DNS resolution and TCP connectivity to the documented database endpoint. Do not
run `secretsmanager get-secret-value` in shared terminal output because it can
print the database password.

## State Locking

An S3 lock file prevents concurrent Terraform state writes. If an operation says
the state is locked:

1. Identify the operator and command shown in the lock information.
2. Confirm no Terraform process or automation is still running.
3. Wait for a slow operation to finish before taking action.
4. Use `terraform force-unlock LOCK_ID` only for a verified stale lock and only
   with the exact lock ID from Terraform.

Never delete the S3 lock object manually while another operation may be active.

## Final Reconciliation

After recovery, create a fresh plan:

```bash
terraform plan -var-file=terraform.tfvars -out=tfplan
terraform show -no-color tfplan
```

The environment is reconciled when Terraform reports no changes and the public
health endpoint, ALB target, Auto Scaling instance, and Systems Manager status are
healthy.

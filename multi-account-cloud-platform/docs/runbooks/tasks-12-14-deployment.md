# Tasks 12–14 Deployment Order

These configurations are prepared and planned, but they have not been applied.
Run each saved plan only after reviewing it and confirming the expected AWS cost.

## 1. Shared Services

Review `live/shared-services/shared-services.tfplan`. It creates the GitHub OIDC
provider and Terraform deployment roles in Shared Services. Private DNS remains
disabled until a workload VPC exists.

Apply the reviewed Shared Services plan before changing the backend policies so
the IAM role principals already exist.

## 2. Backend authorization

Review `bootstrap/bootstrap-task12.tfplan`. It updates the existing S3 bucket and
KMS key policies in place; it does not replace either resource. Apply it only
after the Shared Services and Development deployment roles exist. Until then,
continue using management-account credentials for backend access.

Add later workload deployment-role ARNs to `bootstrap/terraform.tfvars` before
those roles need direct state access.

## 3. Security prerequisites

Apply and verify `live/security/security.tfplan` before the Development baseline.
Replace `config_kms_key_arn` in the Development variable file with the real
`audit_kms_key_arn` output. Confirm the central audit bucket policy permits AWS
Config delivery from the Development account.

## 4. Development

Review `live/workloads/development/development.tfplan`. The VPC uses one NAT
gateway to limit cost. Applying it starts NAT Gateway, CloudWatch Logs, AWS
Config, and GuardDuty/Security Hub-related charges where enabled.

After applying, verify the Config recorder, flow logs, budget notifications,
role assumption, and remote-state access. Then run a new plan and require
`No changes` before marking Task 14 complete.

## 5. Optional private DNS

After the Development VPC exists, authorize its cross-account hosted-zone
association in Shared Services. Set `private_dns` in the Shared Services root,
apply it, then set `private_zone_id` in the Development root and apply the
association. Keep DNS disabled when the project does not need private names.

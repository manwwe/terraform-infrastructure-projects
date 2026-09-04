# Tasks 12–16 Deployment Order

These configurations are prepared and planned, but they have not been applied.
Run each saved plan only after reviewing it and confirming the expected AWS cost.

## 1. Organization CI access

Review `live/organization/organization-task16.tfplan`. Apply it with the current
management credentials to create the management-account OIDC deployment roles.
The existing account hierarchy is unchanged by this plan.

## 2. Security

Review and apply `live/security/security-task16.tfplan`. This creates the
security foundation and its OIDC deployment roles. Verify audit delivery and
Development enrollment before continuing.

## 3. Shared Services

Review `live/shared-services/shared-services.tfplan`. It creates the GitHub OIDC
provider and Terraform deployment roles in Shared Services. Private DNS remains
disabled until a workload VPC exists.

Apply the reviewed Shared Services plan before changing the backend policies so
the IAM role principals already exist.

## 4. Development and Production

Replace `config_kms_key_arn` in both workload variable files with the real
`audit_kms_key_arn` Security output. Confirm the central audit bucket policy
permits AWS Config delivery from both accounts.

Review and apply the Development plan first. Complete its telemetry, recovery,
and no-change checks before reviewing the Production plan. Production uses two
NAT gateways and therefore costs more than Development.

## 5. Backend authorization

Review `bootstrap/bootstrap-task12.tfplan`. It updates the existing S3 bucket and
KMS key policies in place; it does not replace either resource. Apply it only
after all Organization, Security, Shared Services, Development, and Production
deployment roles exist. Until then, continue using management-account
credentials for backend access.

Add later workload deployment-role ARNs to `bootstrap/terraform.tfvars` before
those roles need direct state access.

## 6. Optional private DNS

After the Development VPC exists, authorize its cross-account hosted-zone
association in Shared Services. Set `private_dns` in the Shared Services root,
apply it, then set `private_zone_id` in the Development root and apply the
association. Keep DNS disabled when the project does not need private names.

# Development Teardown

Teardown is destructive. Preserve any scores you need before proceeding, verify
the AWS account and Region, and keep the remote-state backend until the environment
has been removed and verified.

## 1. Confirm the Target Environment

From `environments/dev`:

```bash
aws sts get-caller-identity
terraform workspace show
terraform state list
```

Confirm that the backend and variables refer to development. This project uses a
dedicated state key rather than separate Terraform CLI workspaces; the expected
workspace is `default`.

## 2. Back Up Scores if Needed

Scores are application data stored in RDS. Export them through an approved
database workflow before destruction if they must be retained. Do not write the
database password into shell history, documentation, or an unencrypted file.

## 3. Create and Review a Destroy Plan

```bash
terraform init -backend-config=backend.hcl
terraform plan -destroy -var-file=terraform.tfvars -out=destroy.tfplan
terraform show -no-color destroy.tfplan
```

Confirm that the plan targets only the development state. Pay particular attention
to RDS, networking, and the state key in use.

## 4. Apply Only the Reviewed Plan

```bash
terraform apply destroy.tfplan
```

Do not substitute an unsaved destroy command after reviewing the plan. If state or
configuration changes, discard the old plan and create a new one.

## 5. Verify Environment Removal

```bash
terraform state list
terraform plan -var-file=terraform.tfvars
```

An empty environment state and a plan proposing a complete fresh deployment show
that managed development resources were removed. The remote state object and its
history remain in S3 for audit and recovery.

## 6. Retain the Backend by Default

The bootstrap state bucket is shared infrastructure and has deletion safeguards.
Do not destroy it as part of routine environment teardown. Removing it is a
separate, intentional operation that requires confirming no environment uses it,
handling all versioned objects and lock files, and explicitly changing the
bootstrap deletion safeguards.

Never delete the backend first: doing so removes Terraform's authoritative record
before the resources it manages are gone.

## Production Teardown Safeguards

The production root is not applied in this stage, so there is nothing to tear
down. If production is applied later, its RDS deletion protection deliberately
blocks routine destruction. Teardown requires a separate reviewed change that
disables deletion protection while keeping `skip_final_snapshot = false` and the
final snapshot identifier configured. Confirm the production state key and
preserve the resulting snapshot before any later backend cleanup.

# Terraform State Recovery

Use this procedure only when the state object is missing or corrupted. Do not
restore old state to undo an infrastructure change; fix the configuration and
apply a corrective plan instead.

## Preparation

1. Stop CI applies and tell other operators not to run Terraform.
2. Record the affected root, state key, current Git commit, and incident time.
3. Confirm no lock object exists for an active operation.
4. Save the current object version and checksum before changing anything.

```bash
aws s3api list-object-versions \
  --bucket "$STATE_BUCKET" \
  --prefix "$STATE_KEY" \
  --query 'Versions[].{VersionId:VersionId,LastModified:LastModified,IsLatest:IsLatest}'

aws s3api get-object \
  --bucket "$STATE_BUCKET" \
  --key "$STATE_KEY" \
  --version-id "$CURRENT_VERSION_ID" \
  current-state-backup.tfstate
```

## Restore

Download the last known-good version, inspect it with `terraform show`, and copy
it back as a new current S3 object version. Never delete the intervening versions.

```bash
aws s3api get-object \
  --bucket "$STATE_BUCKET" \
  --key "$STATE_KEY" \
  --version-id "$GOOD_VERSION_ID" \
  recovered.tfstate

terraform show recovered.tfstate

aws s3api put-object \
  --bucket "$STATE_BUCKET" \
  --key "$STATE_KEY" \
  --body recovered.tfstate \
  --server-side-encryption aws:kms \
  --ssekms-key-id "$STATE_KMS_KEY_ARN"
```

## Validate

Run `terraform init -reconfigure`, `terraform state list`, and a refresh-only
plan for the affected root. Review every proposed state update before applying
it. Then run a normal saved plan. Resume CI only after the plan matches the
actual infrastructure and the state lock is released.

Keep the downloaded backups in encrypted incident storage and remove local
copies after the incident record is complete.

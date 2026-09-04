# State Management

## Implemented Backend

The bootstrap root creates an Amazon S3 bucket with server-side encryption,
versioning, public-access blocking, and deletion safeguards. Development stores
Terraform state in that bucket and uses native S3 lock files through
`use_lockfile = true`. Production is configured to use a different state object
in the same protected backend.

The development state key is:

```text
multi-environment-web-app/dev/terraform.tfstate
```

The production state key is:

```text
multi-environment-web-app/prod/terraform.tfstate
```

The local `backend.hcl` file selects the bucket, key, Region, encryption, and lock
settings. It is ignored by Git because its values are account-specific.

## Bootstrap Process

The state bucket must exist before it can store Terraform state. The bootstrap
root therefore starts with local state:

1. Initialize and apply `bootstrap/` locally.
2. Create `bootstrap/backend.hcl` from its example using the new bucket name.
3. Reinitialize with `terraform init -migrate-state -backend-config=backend.hcl`.
4. Confirm the migrated bootstrap state before removing local backup copies.

The detailed commands and safeguards are in
[the bootstrap guide](../bootstrap/README.md).

## Environment Isolation

Development and production use separate roots and keys. Confirm the exact key
before every initialization, plan, state command, or apply. Production must never
share the development state object. Access policies should scope operators to
only the environment state and lock objects they require.

## Lock Recovery

When Terraform reports a lock, identify the active operation and wait for it to
finish. Use `terraform force-unlock` only after verifying that the lock is stale
and no Terraform process or automation still owns it. Do not delete S3 lock files
manually during an active operation.

## Security and Retention

- Keep S3 public-access blocking, encryption, and versioning enabled.
- Grant operators only the state and lock-object permissions they require.
- Never commit local state, backup state, backend configuration, variable files,
  or saved plans.
- Retain the backend during normal environment teardown.
- Treat backend deletion as a separate operation after every dependent
  environment has been removed and its recovery requirements are satisfied.

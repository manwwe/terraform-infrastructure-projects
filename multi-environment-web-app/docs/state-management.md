# State Management

## Backend

Development and production will store Terraform state in an encrypted, versioned Amazon S3 bucket. Native S3 state locking will be enabled with `use_lockfile = true`.

## Environment Isolation

Each environment will use a separate Terraform root configuration and state object:

```text
multi-environment-web-app/dev/terraform.tfstate
multi-environment-web-app/prod/terraform.tfstate
```

Environment-specific IAM policies will restrict access to the corresponding state and lock objects. Production state will have tighter write permissions.

## Bootstrap Process

The `bootstrap/` root configuration will eventually create the backend infrastructure. It will initially use local state because the remote backend cannot be used before its S3 bucket exists.

After the backend is created:

1. Configure the development and production S3 backends.
2. Initialize each environment separately.
3. Verify that each environment uses a distinct state key.
4. Protect or migrate the bootstrap state.

## Security and Recovery

- Block all public access to the state bucket.
- Enable S3 versioning for state recovery.
- Enable server-side encryption.
- Grant access through least-privilege IAM policies.
- Never commit local state, backup state, or plan files.
- Use force-unlock only after confirming that no active Terraform operation owns the lock.

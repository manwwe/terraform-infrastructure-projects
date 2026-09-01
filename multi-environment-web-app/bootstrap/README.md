# Backend Bootstrap

This root module creates the S3 bucket used by the development and production Terraform backends.

## Resources

- Globally unique bucket name derived from the AWS account ID
- S3 versioning
- Server-side encryption with Amazon S3 managed keys
- Complete public-access blocking
- Bucket policy that denies insecure transport
- Destruction protection

Native S3 state locking does not require a separate lock resource. The environment backend configurations will enable it with `use_lockfile = true`.

## Usage

Copy the example variables file and set the owner tag:

```shell
cp terraform.tfvars.example terraform.tfvars
```

### First deployment

The state bucket cannot store this module's state until the bucket exists. For
the first deployment, temporarily move `backend.tf` outside this directory so
Terraform uses local state:

```shell
mv backend.tf ../backend.tf.bootstrap
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
mv ../backend.tf.bootstrap backend.tf
```

Use the bucket name shown by `terraform output` to create the local backend
configuration:

```shell
cp backend.hcl.example backend.hcl
```

Replace the placeholder bucket name in `backend.hcl`, then migrate the local
state into S3:

```shell
terraform init -migrate-state -backend-config=backend.hcl
terraform plan
```

Confirm the migration when prompted. The final plan should report no changes.
Keep the local state file until you verify that Terraform can read the remote
state, then remove it from your working directory. State files and
`backend.hcl` are excluded from Git.

### Subsequent initialization

After the state bucket and remote state exist, authenticate to the target AWS
account and run:

```shell
terraform init -backend-config=backend.hcl
terraform fmt -check
terraform validate
terraform plan
```

## Safety

The state bucket uses `prevent_destroy = true` and `force_destroy = false`. Removing it requires an intentional configuration change, and a non-empty bucket cannot be deleted accidentally.

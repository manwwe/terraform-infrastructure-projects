# Naming and Tagging Conventions

## Resource Names

Use this pattern:

`<project>-<environment>-<purpose>`

Examples:

- `macp-dev-vpc`
- `macp-prod-flow-logs`
- `macp-shared-terraform-state`

## Standard Values

| Field       | Allowed values                                      |
| ----------- | --------------------------------------------------- |
| Project     | `multi-account-cloud-platform`                      |
| Environment | `organization`, `security`, `shared`, `dev`, `prod` |
| ManagedBy   | `Terraform`                                         |

## Required Tags

Every supported resource must include:

```hcl
tags = {
  Project     = "multi-account-cloud-platform"
  Environment = var.environment
  Owner       = var.owner
  ManagedBy   = "Terraform"
}
```

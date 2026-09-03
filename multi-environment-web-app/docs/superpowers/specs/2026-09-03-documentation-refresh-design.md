# Documentation Refresh Design

## Goal

Make the project documentation accurately describe the deployed development
environment and give another engineer enough information to deploy, verify,
recover, and remove it safely.

## Documentation Structure

The project README will become the entry point. It will summarize the working
Snake application, implemented infrastructure, repository layout, prerequisites,
quick-start sequence, validation commands, current limitations, and links to the
detailed guides.

The existing focused documents will be updated in place:

- `docs/architecture.md` will describe the implemented HTTP request path,
  development topology, database-backed score flow, and environment boundaries.
- `docs/security.md` will distinguish implemented controls from future production
  safeguards and will not claim that HTTPS or CloudWatch application logging is
  present.
- `docs/testing.md` will list tests that exist today and separate them from future
  checks.
- `docs/implementation-plan.md` will show completed development milestones and a
  concise remaining-work section.

Three operational guides will be added:

- `docs/deployment.md` for prerequisites, bootstrap, initialization, planning,
  applying, output discovery, and post-deployment checks.
- `docs/recovery.md` for common Terraform, Auto Scaling, application, and database
  diagnostic paths, including the recovered ASG taint scenario encountered during
  development.
- `docs/teardown.md` for an ordered, plan-first destruction workflow that protects
  remote state and avoids deleting the backend prematurely.

## Source of Truth and Scope

Documentation will describe only resources represented by the current Terraform
configuration and behavior verified in development. Exact account-specific ARNs,
resource IDs, public IP addresses, database endpoints, secret ARNs, and generated
ALB hostnames will not be committed.

The guides will explicitly state:

- Development is implemented and deployed.
- Production is not implemented.
- Client traffic currently uses HTTP on port 80.
- HTTPS, Route 53, and a custom domain are outside this project's current scope.
- CloudWatch application/system log shipping, alarms, and CI automation remain
  future work.

Local `backend.hcl` and `terraform.tfvars` files will be referenced but never
shown with user-specific values or committed.

## Architecture Diagram

The diagram will show one AWS Region containing a VPC across two Availability
Zones. It will include:

- Internet clients
- An internet gateway
- An Application Load Balancer spanning two public subnets
- An Auto Scaling group using two private application subnets
- One current development EC2 instance, while showing the group's multi-subnet
  placement
- RDS PostgreSQL across a two-subnet database subnet group
- A NAT gateway in the first public subnet for application egress
- Systems Manager and Secrets Manager dependencies
- The HTTP, application, PostgreSQL, management, secret-retrieval, and outbound
  paths

The editable source will be `docs/diagrams/development-architecture.drawio`. Its
exported companion will be `docs/diagrams/development-architecture.svg`, embedded
in `docs/architecture.md`. The SVG must remain readable in GitHub's light and dark
themes and must not contain account-specific resource identifiers.

## Operational Safety

Every mutating Terraform command will be preceded by initialization and a saved
plan. The deployment guide will instruct readers to inspect a plan before apply.
The teardown guide will keep backend destruction separate from environment
destruction and warn that the S3 state bucket has deletion safeguards.

Troubleshooting commands will avoid printing secret values. Database checks will
use the application health endpoint or service logs rather than retrieving and
displaying the RDS password.

## Verification

The refresh will be checked by:

1. Scanning for stale future-tense claims about already deployed resources.
2. Scanning for account IDs, concrete ARNs, deployed endpoints, and secret values.
3. Verifying every relative Markdown link resolves to a repository file.
4. Parsing the Draw.io XML and SVG as XML.
5. Rendering the SVG for visual inspection.
6. Running Terraform formatting and application tests to ensure documentation
   work did not alter implementation behavior.
7. Running `git diff --check` to catch whitespace errors.

## Alternatives Considered

### Update only the README

This would correct the most visible stale status but leave architecture, security,
and testing pages inaccurate. It would also provide no safe operational workflow.

### Document the planned production environment

This would make the portfolio look broader but could imply that unimplemented
controls exist. The refresh will mention production only as remaining work.

### Use only a text diagram

A text diagram is easy to maintain but does not satisfy the roadmap's editable
architecture-asset goal. Draw.io source plus SVG provides both maintainability and
an immediately viewable result.

## Non-Goals

This milestone will not change Terraform resources, deploy infrastructure, add
production configuration, configure monitoring, create CI workflows, or run
`terraform apply` or `terraform destroy`.

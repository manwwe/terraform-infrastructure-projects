# Multi-Environment Web Application

> **Status:** Development environment deployed and verified

This project runs a small Flask Snake game on AWS. Scores are stored in Amazon
RDS for PostgreSQL. Terraform creates a three-tier network, an internet-facing
Application Load Balancer, private EC2 instances in an Auto Scaling group, and a
private database.

## Implemented Architecture

- One VPC across two Availability Zones
- Public subnets for the Application Load Balancer and NAT gateway
- Private application subnets for EC2 Auto Scaling
- Private database subnets for RDS PostgreSQL
- Systems Manager administration without SSH
- RDS-managed credentials in Secrets Manager
- Encrypted, versioned S3 remote state with native locking

Client traffic currently uses HTTP on port 80. HTTPS, DNS, production, CI, and
CloudWatch application log shipping are outside the current implementation.

## Repository Layout

```text
multi-environment-web-app/
├── application/       Flask application, Snake game, and Python tests
├── bootstrap/         S3 remote-state bootstrap configuration
├── docs/              Architecture and operating guides
├── environments/dev/  Deployed development root module
└── modules/            Reusable Terraform modules
```

## Prerequisites

- Terraform `~> 1.16.0`
- AWS CLI v2
- AWS credentials for the intended account and Region
- Python 3 for local application tests

## Quick Start

Follow the [development deployment guide](docs/deployment.md). It covers remote
state bootstrap, local ignored configuration files, validation, planning,
deployment, and health checks.

After deployment, print the application URL from `environments/dev`:

```bash
echo "http://$(terraform output -raw application_load_balancer_dns_name)"
```

## Validation

```bash
terraform fmt -check -recursive .
terraform -chdir=modules/compute test
terraform -chdir=modules/load-balancer test

cd application
python -m pytest
```

See the [testing strategy](docs/testing.md) for setup details and the checks that
remain to be automated.

## Documentation

- [Architecture](docs/architecture.md)
- [Deployment](docs/deployment.md)
- [Recovery](docs/recovery.md)
- [Teardown](docs/teardown.md)
- [Security](docs/security.md)
- [Testing](docs/testing.md)
- [State management](docs/state-management.md)
- [Implementation status](docs/implementation-plan.md)
- [Architecture decisions](docs/decisions/)

## Current Limitations

- Only the development environment is implemented.
- Client traffic is HTTP rather than HTTPS.
- Development uses one EC2 instance, one NAT gateway, and Single-AZ RDS to limit
  cost.
- CloudWatch application/system log shipping and alarms are not configured.
- CI, linting, security scanning, and tests for several infrastructure modules
  remain future work.

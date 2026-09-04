# Multi-Environment Web Application

> **Status:** Production is deployed and verified; the development environment
> was deployed, verified, and destroyed. Remaining work is limited to optional
> operational improvements, broader automated coverage, and recovery testing.

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
- An isolated production root with dual NAT gateways, Multi-AZ RDS, and a
  two-instance minimum
- CloudWatch collection for application, Nginx, and cloud-init logs
- Essential ALB, Auto Scaling, EC2 CPU, RDS CPU, and RDS storage alarms

Client traffic currently uses HTTP on port 80. HTTPS, DNS, CI, and CloudWatch
application log shipping are outside the current implementation.

## Repository Layout

```text
multi-environment-web-app/
├── application/       Flask application, Snake game, and Python tests
├── bootstrap/         S3 remote-state bootstrap configuration
├── docs/              Architecture and operating guides
├── environments/dev/  Development root module
├── environments/prod/ Deployed production root module
└── modules/            Reusable infrastructure and observability modules
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

After deployment, print the application URL from the target environment:

```bash
echo "http://$(terraform output -raw application_load_balancer_dns_name)"
```

Current production URL:

```text
http://multi-environment-web-app-prod-a-1859276092.us-east-1.elb.amazonaws.com
```

## Validation

```bash
terraform fmt -check -recursive .
terraform -chdir=modules/observability test
terraform -chdir=environments/prod test
terraform -chdir=modules/security test
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
- [Architecture decisions](docs/decisions/)

## Current Limitations

- Client traffic is HTTP rather than HTTPS.
- Development still uses one EC2 instance, one NAT gateway, and Single-AZ RDS to
  limit cost.
- Alarm notifications and CloudWatch dashboards are not configured.
- CI, linting, security scanning, and tests for several infrastructure modules
  remain future work.

# Multi-Environment Web Application

> **Status:** Design phase

This project will demonstrate how to build and manage a secure, highly available web application infrastructure on AWS with Terraform. It will use reusable modules and separate development and production environments.

## Planned Architecture

- A VPC spanning two Availability Zones
- Public subnets for an internet-facing Application Load Balancer and NAT gateways
- Private application subnets for EC2 instances in an Auto Scaling group
- Private database subnets for Amazon RDS for PostgreSQL
- Security groups that restrict traffic between infrastructure layers
- AWS Systems Manager for administrative access
- Amazon CloudWatch for logs, metrics, and alarms
- AWS Secrets Manager for database credentials
- Encrypted, versioned Amazon S3 remote state with native state locking

## Documentation

- [Architecture](docs/architecture.md)
- [Implementation plan](docs/implementation-plan.md)
- [Security](docs/security.md)
- [State management](docs/state-management.md)
- [Testing strategy](docs/testing.md)
- [Architecture decisions](docs/decisions/)

## Planned Environments

| Environment | Purpose | Availability approach |
| --- | --- | --- |
| Development | Testing infrastructure changes at lower cost | Reduced capacity with the same architectural boundaries |
| Production | Running a resilient public web application | Multi-AZ compute and database resources |

## Current Scope

This phase defines the architecture and implementation sequence. Terraform configuration, validation commands, deployment instructions, and architecture diagram assets will be added after the design is approved.

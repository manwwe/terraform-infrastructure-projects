# Terraform Infrastructure Projects

An in-progress portfolio of Terraform projects designed to demonstrate practical infrastructure-as-code skills on AWS. The projects progress from reusable multi-environment infrastructure to a production-oriented, multi-account cloud platform.

> **Status:** Two active Terraform projects. The multi-environment web application has a verified production deployment; the multi-account cloud platform has its foundation, CI workflows, and deployment plans implemented, with final AWS verification and recovery exercises still pending.

## Skills Demonstrated

- Reusable and versioned Terraform modules
- Multi-environment and multi-account architecture
- AWS networking, compute, containers, databases, and DNS
- Identity and access management, secrets, logging, and security controls
- Remote state, state locking, policy checks, and disaster recovery
- Automated Terraform plan and apply workflows

## Projects

### Mid-level

#### 1. Multi-environment web application

Build reusable infrastructure for development and production environments, including:

- VPC with public and private subnets
- Application load balancer
- Compute instances
- Managed database
- Reusable Terraform modules
- Remote state and state locking

Directory: [`multi-environment-web-app/`](multi-environment-web-app/)

### High-level

#### 2. Multi-account cloud platform

Build a production-oriented platform spanning development, staging, production, and shared-services AWS accounts, including:

- Centralized networking and DNS
- Centralized monitoring and security
- Reusable versioned modules
- Automated deployments and policy checks
- Disaster recovery planning
- Remote state management

Directory: [`multi-account-cloud-platform/`](multi-account-cloud-platform/)

## Repository Structure

```text
.
├── multi-account-cloud-platform/
└── multi-environment-web-app/
```

## Implementation Roadmap

1. Multi-environment web application
2. Multi-account cloud platform

Each active project has its own documentation, architecture decisions, deployment instructions, and validation steps.

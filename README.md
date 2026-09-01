# Terraform Infrastructure Projects

An in-progress portfolio of Terraform projects designed to demonstrate practical infrastructure-as-code skills on AWS. The projects progress from reusable multi-environment infrastructure to a production-oriented, multi-account cloud platform.

> **Status:** In progress. Infrastructure code and documentation will be added incrementally as each project milestone is completed.

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

#### 2. Containerized application on ECS

Build a container-based application platform on AWS, including:

- ECS with AWS Fargate
- Elastic Container Registry
- Application load balancer
- Service autoscaling
- IAM roles and policies
- Centralized logging
- Secrets management
- CI/CD workflows for Terraform plan and apply

Directory: [`containerized-app-ecs/`](containerized-app-ecs/)

### High-level

#### 3. Multi-account cloud platform

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
├── containerized-app-ecs/
├── multi-account-cloud-platform/
└── multi-environment-web-app/
```

## Implementation Roadmap

1. Multi-environment web application
2. Containerized application on ECS
3. Multi-account cloud platform

Each project will gain its own documentation, architecture decisions, deployment instructions, and validation steps as it is implemented.

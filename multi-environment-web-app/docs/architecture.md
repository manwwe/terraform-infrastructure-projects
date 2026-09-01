# Architecture

## Overview

The application will use a three-tier AWS architecture distributed across two Availability Zones. Only the Application Load Balancer will accept traffic from the internet. Compute and database resources will remain in private subnets.

## Request Flow

```text
Internet
   |
   | HTTPS
   v
Application Load Balancer
   |
   | HTTP on the application port
   v
EC2 Auto Scaling Group
   |
   | PostgreSQL connection
   v
Amazon RDS for PostgreSQL
```

## Network Design

The VPC will span two Availability Zones. Each Availability Zone will contain:

- One public subnet for the load balancer and outbound network infrastructure
- One private application subnet for EC2 instances
- One private database subnet for RDS

An internet gateway will provide connectivity for public subnets. NAT gateways will provide controlled outbound access from private application subnets. Database subnets will not have a route to the internet.

## Application Layer

An internet-facing Application Load Balancer will terminate HTTPS and distribute requests across EC2 instances. The instances will run in an Auto Scaling group across private application subnets and will not receive public IP addresses.

AWS Systems Manager will provide administrative access without exposing SSH to the internet. Amazon CloudWatch will collect application and infrastructure logs, metrics, and alarms.

## Database Layer

Amazon RDS for PostgreSQL will run in private database subnets. Production will use a Multi-AZ deployment. Automated backups, encryption at rest, and deletion protection will be enabled according to environment requirements.

Database credentials will be stored in AWS Secrets Manager rather than committed to Terraform configuration.

## Security Boundaries

Traffic will follow a restricted chain:

1. The load balancer security group accepts HTTPS from the internet.
2. The application security group accepts application traffic only from the load balancer security group.
3. The database security group accepts PostgreSQL traffic only from the application security group.

IAM roles will grant EC2 instances only the permissions required for Systems Manager, logging, metrics, and secret retrieval.

## Environment Isolation

Development and production will use separate Terraform root configurations and separate state objects. Both environments will consume the same reusable modules while providing different capacity, availability, backup, and protection settings.

## State Management

Terraform state will use an encrypted, versioned S3 backend. Native S3 locking will be enabled with `use_lockfile = true`. Each environment will use a distinct state key and environment-specific IAM permissions.

## Diagram Strategy

The final visual architecture will use a native `.drawio` source file and an exported SVG embedded in this document. Those assets will be created only after the architecture and diagram-generation workflow are finalized.

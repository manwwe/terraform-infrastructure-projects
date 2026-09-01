# ADR 003: Compute Selection

## Status

Accepted

## Context

The project needs to demonstrate virtual-machine provisioning, scaling, load-balancer integration, IAM instance roles, initialization, and private administrative access. Container orchestration is covered by the separate ECS project.

## Decision

Use Amazon EC2 instances managed by an Auto Scaling group and launch template. Run instances across private application subnets and administer them through AWS Systems Manager.

## Consequences

- The project demonstrates EC2 lifecycle and scaling concepts.
- The Auto Scaling group provides instance replacement and horizontal scaling.
- Operating-system maintenance remains part of the workload.
- ECS and Fargate concerns remain isolated to the containerized application project.

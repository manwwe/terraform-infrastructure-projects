# ADR 002: Network Design

## Status

Accepted

## Context

The public web application needs internet access while compute and database resources must remain protected from direct inbound internet traffic.

## Decision

Use a VPC spanning two Availability Zones with three subnet tiers in each zone:

- Public subnets for the internet-facing load balancer and outbound gateways
- Private application subnets for EC2 instances
- Private database subnets for Amazon RDS

Security groups will allow traffic only along the load balancer-to-application-to-database path.

## Consequences

- Only the load balancer is directly reachable from the internet.
- Application instances do not require public IP addresses.
- Database resources have no direct internet route.
- Multi-AZ resources improve availability but increase cost.

# Application Load Balancer Design

## Goal

Expose the development Snake application through an internet-facing AWS
Application Load Balancer while keeping the EC2 instances in private subnets.

## Architecture

A dedicated reusable `load-balancer` module will own the Application Load
Balancer, target group, and listener. The load balancer will span both public
subnets and use the existing load-balancer security group. Its HTTP listener on
port 80 will forward requests to a target group that reaches Nginx on port 80 on
the private application instances.

The development root module will pass the target group ARN to the existing
`compute` module. The compute module already attaches supplied target groups to
its Auto Scaling group and switches from EC2 health checks to ELB health checks.

## Module Interface

The `load-balancer` module will accept:

- A resource name prefix
- The VPC ID
- The public subnet IDs
- The load-balancer security group ID
- The application port, defaulting to 80
- Common tags

It will output:

- The load balancer ARN
- The load balancer DNS name
- The target group ARN
- The target group name

## Request and Health Flow

Internet clients will connect to the load balancer over HTTP on port 80. The
listener will forward traffic to healthy EC2 instances registered by the Auto
Scaling group. The target group will perform HTTP health checks against
`/health`, require an HTTP 200 response, and use a startup-tolerant interval and
threshold configuration.

The existing security-group path remains authoritative:

1. The load-balancer security group accepts public TCP traffic on port 80.
2. The load-balancer security group permits egress to the application security
   group on port 80.
3. The application security group accepts port 80 only from the load-balancer
   security group.

## Reliability and Failure Behavior

The load balancer will be enabled across both public subnets. The target group
will deregister unhealthy instances from request routing, and the Auto Scaling
group will use ELB health status after attachment. A 300-second Auto Scaling
health-check grace period will allow cloud-init and application services to start
before replacement decisions are made.

The listener's default action will only forward to the application target group;
redirects, fixed responses, stickiness, and custom routing rules are outside this
milestone.

## Validation

Terraform tests will verify that:

- The load balancer is internet-facing and uses both supplied public subnets.
- The load balancer uses the supplied security group.
- The target group uses HTTP port 80 and checks `/health` for HTTP 200.
- The listener accepts HTTP on port 80 and forwards to the target group.
- The development Auto Scaling group receives the target group ARN and therefore
  uses ELB health checks.
- The development root exposes the load balancer DNS name.

Formatting, initialization, validation, and tests will run locally. A speculative
development plan will be reviewed when credentials and backend access are
available. No `terraform apply` will be run.

## Alternatives Considered

### Define the resources directly in the development root

This is slightly faster initially but duplicates configuration when production is
added. A module preserves the repository's established reusable architecture.

### Add load-balancing resources to the compute module

This reduces the module count but couples traffic entry and routing to instance
lifecycle management. Keeping them separate makes both interfaces easier to
understand and reuse.

### Configure HTTPS immediately

HTTPS is the correct production destination, but it requires a domain and an ACM
certificate. This development milestone will start with HTTP and add HTTPS and
DNS in a later, explicit change.

## Scope Boundaries

This milestone does not create Route 53 records, request an ACM certificate,
configure HTTPS, enable access logs, add AWS WAF, or alter application behavior.
It also does not change database or network topology.

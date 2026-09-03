# ADR 006: EC2 Compute and Score Application

## Status

Accepted

## Context

The project needs a reusable EC2 compute layer that demonstrates launch templates,
Auto Scaling, private application subnets, Systems Manager administration, instance
initialization, and secure access to an RDS-managed secret.

The compute milestone also needs a small application that exercises the database
without turning application development into the focus of the infrastructure
project. A browser-based Snake game with an anonymous high-score list provides a
visible workload while keeping the data model and API small.

## Decision

Create a reusable `compute` module that owns an EC2 launch template and an Auto
Scaling group. The group will span the private application subnets and its
instances will have no public IP address or SSH key. Administration will use AWS
Systems Manager through the existing EC2 instance profile.

The module will remain application-agnostic. The development environment will
render and supply a user-data script that installs and configures the Snake
application. User data will contain only non-secret configuration, including the
RDS secret ARN, database endpoint, port, and database name.

The application will use Flask behind Gunicorn and Nginx. It will provide:

- A browser-based Snake game
- A health endpoint
- An endpoint that accepts an anonymous score
- An endpoint that returns the highest scores

PostgreSQL will store only each score and its creation timestamp. The application
will accept integer scores from `0` through `1,000,000` and reject other values. It
will create its table with `CREATE TABLE IF NOT EXISTS` so multiple instances can
initialize safely.

When the Flask service starts, it will retrieve the database username and password
from AWS Secrets Manager using the instance role. Credentials will remain in
process memory and will not be written into Terraform configuration, Terraform
state, launch-template user data, or browser responses. If Secrets Manager or RDS
is temporarily unavailable, the service will make five attempts separated by five
seconds, then exit so systemd can restart it.

The health endpoint will report success only when the application can query
PostgreSQL. Before a load balancer is attached, the Auto Scaling group will use EC2
health checks. When target groups are supplied, it will use load-balancer health
checks.

## Compute Module Interface

The module will accept:

- A resource name prefix
- Private application subnet IDs
- The application security group ID
- The EC2 instance profile name
- An EC2 instance type
- Minimum, desired, and maximum capacity
- Plain-text user data that contains no secrets
- An optional set of target group ARNs, defaulting to an empty set
- Common resource tags

The module will resolve the latest x86_64 Amazon Linux 2023 AMI through the
AWS-managed Systems Manager public parameter. The launch template will require
IMDSv2 and use encrypted EBS storage.

Capacity inputs will enforce this relationship:

```text
0 <= minimum <= desired <= maximum
```

The module will output:

- The launch template ID
- The Auto Scaling group name
- The Auto Scaling group ARN

It will perform a rolling instance refresh when a launch-template change requires
instances to be replaced.

## Development Configuration

Development will initially use:

- Instance type `t3.micro`
- Minimum capacity `1`
- Desired capacity `1`
- Maximum capacity `2`

Although only one instance normally runs to control cost, the Auto Scaling group
will be configured with both private application subnets.

## Security Boundaries

- Instances will not have public IP addresses.
- No SSH key or inbound SSH rule will be configured.
- The existing application security group will control inbound traffic.
- The existing instance profile will provide Systems Manager and least-privilege
  access to the specific RDS-managed secret.
- Package downloads and AWS API calls will leave the private application subnets
  through the existing NAT gateway.
- The browser will communicate only with the Flask API and will never receive
  database credentials.

## Validation

The compute milestone will be validated by:

1. Running Terraform formatting, validation, and the repository's static checks.
2. Reviewing the development plan for private subnet placement, the instance
   profile, the application security group, IMDSv2, encrypted storage, and capacity
   values.
3. Deploying development and confirming that the instance is available through
   Systems Manager.
4. Using Systems Manager to verify the systemd services, secret retrieval, table
   creation, score submission, and score persistence.
5. Terminating the instance and confirming that the Auto Scaling group replaces
   it.
6. Testing the game and database-aware health endpoint through the Application
   Load Balancer after the load-balancing milestone.

## Alternatives Considered

### Put application bootstrapping inside the compute module

This would reduce root-module wiring but couple reusable infrastructure to the
Snake demonstration application. Passing user data preserves a clearer module
boundary.

### Pass an AMI ID into the compute module

This would make the module more operating-system-neutral. The additional wiring is
not valuable for this project, which explicitly standardizes on Amazon Linux 2023.

### Use Node.js or Go for the application

Node.js is capable but requires additional runtime setup on Amazon Linux. Go would
produce a small deployable binary but introduce an unnecessary build and artifact
delivery workflow. Flask keeps the service compact and readable.

### Keep the game entirely static

A static game would validate web serving but would not exercise the private RDS
connection or secure secret retrieval. Persisting anonymous scores demonstrates
those infrastructure paths with minimal application complexity.

## Consequences

- The compute module can support other applications by receiving different user
  data.
- The demo validates secure database access without exposing credentials.
- Development normally runs one instance, so it tolerates instance replacement but
  does not provide continuous application availability until capacity is increased.
- Startup depends on NAT connectivity for package installation and AWS API access.
- Using the RDS master credential is acceptable for this learning milestone but a
  production application should use a separate, restricted database user.
- Credential rotation is not handled transparently; the service must restart to
  retrieve a changed secret.

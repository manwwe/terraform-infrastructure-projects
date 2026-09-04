# Production Environment Design

## Goal

Add an isolated production Terraform root that reuses the existing modules while
enforcing stronger availability, recovery, capacity, and network-access
safeguards. This stage must not apply Terraform or create production AWS
resources.

## Architecture

The production configuration will live in `environments/prod` and use a remote
state key distinct from development:
`multi-environment-web-app/prod/terraform.tfstate`. It will instantiate the
existing network, security, IAM, RDS, load-balancer, and compute modules with
production-specific values rather than adding environment switches to the
development root.

The production VPC will span exactly two distinct Availability Zones. Each
Availability Zone will contain a public subnet, a private application subnet,
and a private database subnet. Production will set `single_nat_gateway = false`,
creating one NAT gateway per Availability Zone. Each application subnet will
route outbound traffic through the NAT gateway in the same Availability Zone.

## Production Configuration

The production root will make the following settings explicit:

- RDS PostgreSQL instance class `db.t4g.small`
- Multi-AZ RDS enabled
- 30-day automated backup retention
- RDS deletion protection enabled
- Final snapshots required with a deterministic, environment-specific identifier
- Encrypted RDS storage and RDS-managed credentials, as already provided by the
  shared module
- Auto Scaling minimum, desired, and maximum capacities of 2, 2, and 4
- Application placement across both private application subnets
- Two NAT gateways, one per Availability Zone
- Longer CloudWatch database log retention than development

The public Application Load Balancer will continue to use HTTP on port 80.
HTTPS, certificates, and DNS remain outside this stage.

## Access Controls

Production load-balancer ingress CIDRs will be a required input without a
permissive default. Validation will reject an empty set and the unrestricted
IPv4 CIDR `0.0.0.0/0`. Operators must provide one or more narrower IPv4 CIDRs in
their uncommitted production variables file.

The shared security module will gain an explicit option controlling HTTPS
ingress. Development behavior will remain compatible, while production will
disable port 443 ingress because no HTTPS listener exists in this stage. The
existing security-group chain remains unchanged:

1. Approved client CIDRs can reach the load balancer on port 80.
2. The load balancer can reach application instances only on the application
   port.
3. Application instances accept inbound application traffic only from the load
   balancer security group.
4. RDS accepts PostgreSQL traffic only from the application security group.
5. EC2 instances have no public IP addresses and remain managed through Systems
   Manager.

## Request and Dependency Flow

An approved client sends HTTP traffic to the load balancer. The listener routes
requests to healthy EC2 instances registered by the Auto Scaling group across
both private application subnets. The application retrieves the RDS-managed
credential from Secrets Manager through its existing least-privilege IAM role
and connects to the private Multi-AZ PostgreSQL endpoint.

Application instances use their same-AZ NAT gateways for outbound package and
AWS API access during bootstrap. Database subnets have no internet route.

## Safeguards and Failure Behavior

Production root checks and variable validation will reject a plan when any of
these conditions is true:

- Fewer than two distinct Availability Zones are configured.
- A single shared NAT gateway is selected.
- RDS Multi-AZ or deletion protection is disabled.
- RDS final snapshots are skipped or no final snapshot identifier is supplied.
- Automated backup retention is shorter than 30 days.
- Auto Scaling minimum or desired capacity is below two, maximum capacity is
  below desired capacity, or capacity ordering is invalid.
- Production ingress includes `0.0.0.0/0` or has no allowed CIDR.

Loss of one Availability Zone leaves an application subnet, NAT gateway, ALB
node, and RDS standby in the other zone. Auto Scaling can replace unhealthy
instances up to the configured maximum of four. RDS deletion protection blocks
ordinary destruction; an intentional teardown requires a separate reviewed
change to disable protection, after which Terraform must create a final
snapshot.

## Validation and Tests

Terraform tests with mocked AWS providers will validate the production root
without creating resources. Tests will assert the production state-independent
configuration, including two NAT gateways, RDS Multi-AZ, deletion protection,
final snapshots, 30-day backups, capacity 2/2/4, placement across both
application subnets, restricted ingress, and disabled HTTPS ingress.

Validation will include:

- `terraform fmt -check -recursive .`
- Backend-free initialization and validation for the production root
- Existing module test suites
- New production configuration tests
- Existing Python application tests
- A speculative production plan only when AWS credentials and remote-state
  access are already available and the command is safe

No `terraform apply`, targeted apply, import, state mutation, or production AWS
resource creation is permitted in this stage.

## Documentation

The project documentation will explain production setup, the separate state key,
required restricted ingress CIDRs, planning and review commands, resilience
settings, final-snapshot behavior, validation commands, and the no-apply scope.
Existing development instructions will remain valid.

## Alternatives Considered

### Separate production root with shared modules

This is the selected approach. It preserves independent state and lifecycle
boundaries while reusing module interfaces. Explicit production values and tests
make the safeguards reviewable.

### Copy development and change constants only

This is initially quick, but production guarantees would exist only as copied
values and could drift silently. Root-level checks and focused tests provide a
stronger boundary.

### One root with an environment switch

This reduces duplicated root wiring but introduces conditional resource policy
and increases the risk of planning against the wrong environment or state.
Separate roots make operator intent and remote-state isolation clearer.

## Scope Boundaries

This stage does not add HTTPS, ACM certificates, Route 53 records, AWS WAF,
cross-Region recovery, RDS read replicas, Aurora, bastion hosts, blue/green
deployments, application changes, or observability beyond existing database log
exports and longer retention.

# Testing Strategy

## Static Validation

Every Terraform change will be checked with:

- `terraform fmt -check`
- `terraform validate`
- TFLint
- A Terraform security scanner

## Module Tests

Reusable modules will have Terraform test files that verify important inputs, outputs, resource relationships, and validation rules. Tests should avoid unnecessary infrastructure creation when assertions can be evaluated from a plan.

## Environment Plans

Development and production plans will run independently. Review will focus on:

- Unexpected replacement or deletion
- Public exposure
- Environment-specific capacity and protection settings
- Correct module inputs and outputs
- Correct state and provider configuration

## Integration Testing

The development environment will be deployed first and checked for:

- Load balancer health
- Application reachability through HTTPS
- Auto Scaling group health and replacement behavior
- Private EC2 access through Systems Manager
- Application-to-database connectivity
- Log and metric delivery to CloudWatch

## Production Readiness

Before a production deployment, all automated checks must pass and the development deployment must demonstrate the expected network, security, availability, and recovery behavior.

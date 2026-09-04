# CloudWatch Observability Design

## Goal

Add simple, reusable CloudWatch observability for development and production.
The stage will centralize application and instance logs and create a small set of
essential infrastructure alarms. It will not deploy notification channels or a
dashboard.

## Architecture

A new reusable `modules/observability` Terraform module will own CloudWatch log
groups and alarms. Both environment roots will instantiate it with their own
resource identifiers, retention periods, and thresholds. Development will favor
short retention and low cost; production will retain logs longer and evaluate
alarms against its larger minimum capacity.

The compute bootstrap template will install and configure the Amazon CloudWatch
agent. Instances will send application service logs, Nginx logs, and cloud-init
output to environment-specific log groups. The existing EC2 IAM module will
receive those exact log-group ARNs and grant only the CloudWatch Logs actions
already defined by its scoped policy.

## Module Responsibilities

The observability module will create these log groups:

- Snake application service output written to a dedicated log file
- Nginx access and error logs
- Cloud-init output

It will create these essential alarms:

- ALB unhealthy host count above zero
- Auto Scaling in-service instance count below the environment minimum
- EC2 average CPU utilization above the configured threshold
- RDS CPU utilization above the configured threshold
- RDS free storage space below the configured byte threshold

The module will accept the load balancer ARN suffix, target group ARN suffix,
Auto Scaling group name, RDS instance identifier, minimum healthy instance count,
log retention, and alarm thresholds. It will output the log-group names and ARNs
and alarm names. It will not manage compute, networking, databases, or IAM.

Existing modules will expose only the non-sensitive identifiers required by this
interface. No credential, secret value, or user-data content will be output.

## Environment Settings

Development will retain application and instance logs for 7 days and use
thresholds intended to surface obvious failures without adding high-resolution
metrics. Production will retain logs for 30 days and use the same essential alarm
types with a minimum healthy instance count of two. All alarms will use standard
CloudWatch periods and missing-data behavior suited to the metric:

- Availability and capacity alarms will treat missing data as breaching.
- CPU alarms will treat missing data as missing.
- RDS free-storage alarms will treat missing data as breaching.

To keep the stage simple, alarm actions will be empty. SNS topics, email
subscriptions, incident-management integrations, composite alarms, anomaly
detection, and dashboards are outside scope.

## Log Flow and IAM

During instance bootstrap, the CloudWatch agent package and configuration will be
installed before the application services are considered ready. The systemd unit
will append application stdout and stderr to a dedicated file. The agent will
read that file plus the selected Nginx and cloud-init files and publish them to
the log groups provided through template variables. Each stream name will
identify its instance.

The observability module creates the log groups first. Their ARNs flow into the
IAM module, which grants the EC2 role permission to describe streams and create
and write streams only in those groups. The log-group names flow into the compute
user-data template. Explicit Terraform dependencies will ensure log groups and
IAM policy exist before the Auto Scaling group begins launching instances.

If CloudWatch agent installation or configuration fails, the bootstrap script's
existing strict shell settings will stop initialization and expose the failure in
cloud-init output. Application health remains based on the existing ALB `/health`
check and does not depend on log ingestion.

## Validation

The observability module will use variable validation for supported retention
periods, positive thresholds, and required identifiers. Terraform tests with a
mocked AWS provider will verify:

- Correct log-group count, names, encryption-compatible settings, and retention
- Correct ALB, Auto Scaling, EC2, and RDS metric namespaces and dimensions
- Environment minimum capacity is used by the capacity alarm
- Alarm actions remain empty
- The IAM role is scoped to the generated log groups
- Both roots pass the generated log-group names to compute bootstrap
- Development and production use their intended retention periods

The complete validation suite will include formatting, backend-free validation
for both roots, all Terraform tests, and all application tests. A speculative
plan may run only when the relevant ignored backend and variable files already
exist and credentials are valid. No `terraform apply` is authorized by this
stage.

## Documentation

Architecture, deployment, testing, security, recovery, and implementation-status
documentation will describe the new log flow and alarms. Operator guidance will
include commands for listing alarms, viewing alarm history, finding log groups,
and tailing log streams without retrieving secrets.

## Alternatives Considered

### Reusable observability module

This is the selected approach. It gives both roots the same interface and tests
while keeping telemetry lifecycle separate from compute, load balancing, and RDS.

### Environment-local observability resources

This avoids a module initially but duplicates log groups, alarms, validation, and
tests. The two environments would be more likely to drift.

### Add telemetry resources to existing service modules

This reduces the module count but couples alarms and retention policies to
resource creation. A separate module keeps service modules focused and allows
environment-specific monitoring policy without changing their internals.

## Scope Boundaries

This stage excludes SNS, email or chat notifications, dashboards, AWS X-Ray,
OpenTelemetry, distributed tracing, custom application metrics, log metric
filters, WAF logging, ALB access logs, VPC Flow Logs, CloudTrail, GuardDuty,
high-resolution metrics, and automated remediation.

# Teardown Guide

This project contains resources that are intentionally difficult to destroy.
Export state, record account ownership, and review the final bill before teardown.
Never start with the bootstrap stack or AWS Organization.

## Order

1. Remove application resources not managed by this project.
2. Destroy the Production workload root.
3. Destroy the Development workload root.
4. Remove private-zone associations, then destroy Shared Services resources.
5. Disable member enrollment and destroy Security services only after exporting
   findings and confirming audit retention requirements.
6. Detach custom SCPs and remove delegated administrators through the
   Organization root.
7. Close or remove member accounts manually only when account retention is no
   longer required.
8. Retain the bootstrap state bucket and KMS key until every other state and
   recovery artifact has been exported and verified.

For each Terraform root, create a destroy plan, review it, and apply only that
saved plan through an approved environment. A root may be removed only after its
state is empty and AWS API checks show no retained billable resources.

## Intentionally retained resources

The Terraform state S3 bucket, its object versions, and its KMS key use
`prevent_destroy`. Central audit buckets and their KMS key are also protected.
Retain them by default. If permanent deletion is approved, first copy required
state and audit evidence to an approved archive, document the retention decision,
remove `prevent_destroy` in a reviewed commit, and use AWS deletion procedures.

AWS accounts are configured with `close_on_deletion = false`. Removing an account
resource from Terraform does not close the AWS account. Account closure, leaving
the organization, and deleting the organization are separate manual governance
decisions.

## Final verification

- Run Cost Explorer or Cost and Usage Reports after the next billing cycle.
- Check every account and Region for NAT gateways, elastic IPs, log groups,
  Config recorders, GuardDuty detectors, Security Hub, hosted zones, and S3 data.
- Preserve final state versions, plans, CloudTrail evidence, and approvals.
- Remove GitHub environment secrets and disable deployment workflows.

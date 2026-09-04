# Service Control Policy Recovery

Use this runbook when an SCP blocks legitimate Development administration or
deployment. Test recovery in Development before changing Production or an OU.

## Diagnose

1. Preserve the failed command, principal ARN, request ID, and CloudTrail event.
2. List policies attached to the affected account and every parent OU.
3. Compare the denied action, resource, Region, and condition with each policy.
4. Confirm the denial is an SCP denial rather than an IAM or resource-policy denial.

```bash
aws organizations list-parents --child-id "$ACCOUNT_ID"
aws organizations list-policies-for-target \
  --target-id "$TARGET_ID" \
  --filter SERVICE_CONTROL_POLICY
aws organizations describe-policy --policy-id "$POLICY_ID"
```

## Recover

Prefer a narrow policy correction committed through Git. If urgent access is
required, detach only the identified faulty policy from the narrowest affected
Development target. Do not detach `FullAWSAccess`, disable Organizations, or
weaken unrelated audit protections.

```bash
aws organizations detach-policy \
  --policy-id "$POLICY_ID" \
  --target-id "$DEVELOPMENT_TARGET_ID"
```

Generate a Terraform plan immediately. Update the policy source or attachment
map so Terraform agrees with the approved recovery action, review the plan, and
apply it through the protected workflow. Reattach the corrected policy to
Development and rerun the originally denied operation.

## Closeout

Verify CloudTrail captured the detach and reattach events. Record duration,
approver, affected target, cause, and corrective commit. Promote the corrected
policy beyond Development only after a no-change plan and a successful control
test.

# Break-Glass Access Runbook

## Purpose

Use break-glass access only when normal IAM Identity Center and deployment-role
paths are unavailable and urgent action is required to protect the organization.

## Preparation

- Maintain one emergency role in each account with a unique name and no routine
  group assignment.
- Require MFA and a maximum one-hour session.
- Store recovery material in an encrypted password manager with access requiring
  two authorized people.
- Alert on every role assumption and root-user sign-in.
- Test the procedure quarterly in Development before testing other accounts.

## Activation

1. Open an incident record and document why normal access is unavailable.
2. Obtain approval from two authorized custodians.
3. Retrieve the emergency credential and MFA device information.
4. Assume the role with a unique incident session name.
5. Confirm the target account with `aws sts get-caller-identity`.
6. Perform only the actions required to contain or recover the incident.
7. Preserve CloudTrail and relevant service logs.
8. End the session as soon as normal access is restored.

## Recovery and Closure

1. Revoke active emergency sessions when supported.
2. Rotate any credential or recovery material exposed during activation.
3. Confirm CloudTrail contains the complete session and actions.
4. Review changes through Terraform and reconcile any necessary emergency drift.
5. Record the timeline, approvers, actions, evidence, and follow-up controls.
6. Close the incident only after normal access and monitoring are verified.

## Prohibited Use

- Routine deployment or troubleshooting
- Bypassing a required production review
- Sharing credentials in chat, email, tickets, or source control
- Disabling audit logging except when required to restore the audit service itself
- Deleting evidence or altering the incident trail

## Quarterly Test

Test access in Development, confirm the alert reaches the security owner, perform
a read-only identity check, end the session, rotate the test credential, and
record the result. Do not test by changing or deleting production resources.

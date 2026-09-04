# Account Compromise Response

Treat unexpected root activity, unknown federation, exposed credentials, or
unexplained security findings as a potential account compromise.

## Contain

1. Open an incident channel and record times in UTC.
2. Use the Security account or documented break-glass path from a clean device.
3. Disable or revoke the suspected access key, session, identity provider, or
   role trust without deleting evidence.
4. Restrict the affected account with the approved quarantine SCP when doing so
   will not interrupt centralized logging.
5. Preserve CloudTrail, Config, GuardDuty, Security Hub, VPC Flow Log, and S3
   access-log delivery.
6. Contact AWS Support for suspected root-account or organization compromise.

Do not destroy resources, rotate every credential blindly, clear findings, or
modify audit buckets during initial containment.

## Investigate

- Establish the first known malicious event and all affected principals.
- Review CloudTrail management and data events around that time.
- Compare Config history and Terraform state with deployed resources.
- Identify persistence: access keys, roles, policies, identity providers,
  network paths, snapshots, AMIs, Lambda code, and secrets.
- Export relevant findings and object version IDs into encrypted evidence storage.
- Record hashes for exported evidence and limit access to incident responders.

## Eradicate and recover

Remove confirmed persistence through reviewed changes, rotate affected secrets,
and rebuild disposable resources from trusted code. Restore service in stages,
keeping quarantine controls until security telemetry is healthy. Generate and
review Terraform plans for every affected root; investigate unexplained drift
instead of accepting it automatically.

## Closeout

Confirm new credentials and federation paths work, no malicious sessions remain,
central logging is complete, and security findings are resolved with evidence.
Document the timeline, root cause, affected data, AWS Support case, recovery
commits, and prevention work.

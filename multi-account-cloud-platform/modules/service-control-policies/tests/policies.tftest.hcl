mock_provider "aws" {}

run "preventive_guardrails" {
  command = plan

  variables {
    allowed_regions = [
      "us-east-1",
      "us-west-2"
    ]

    policy_targets = {
      protect_organization = [
        "ou-exam-11111111"
      ]
      protect_audit = [
        "ou-exam-11111111"
      ]
      restrict_regions = [
        "ou-exam-22222222"
      ]
      protect_s3_public_access = [
        "ou-exam-33333333"
      ]
    }
  }

  assert {
    condition     = length(aws_organizations_policy.this) == 4
    error_message = "Exactly four preventative policies must be created."
  }

  assert {
    condition = strcontains(
      aws_organizations_policy.this["protect_organization"].content,
      "organizations:LeaveOrganization"
    )
    error_message = "The organization policy must deny leaving the organization."
  }

  assert {
    condition = (
      strcontains(
        aws_organizations_policy.this["protect_audit"].content,
        "cloudtrail:StopLogging"
      ) &&
      strcontains(
        aws_organizations_policy.this["protect_audit"].content,
        "config:StopConfigurationRecorder"
      )
    )
    error_message = "The audit policy must protect CloudTrail and AWS Config."
  }

  assert {
    condition = (
      strcontains(
        aws_organizations_policy.this["restrict_regions"].content,
        "aws:RequestedRegion"
      ) &&
      strcontains(
        aws_organizations_policy.this["restrict_regions"].content,
        "us-east-1"
      )
    )
    error_message = "The Region policy must use the requested-Region condition."
  }

  assert {
    condition = strcontains(
      aws_organizations_policy.this["protect_s3_public_access"].content,
      "s3:DeleteBucketPublicAccessBlock"
    )
    error_message = "The S3 policy must protect bucket public-access settings."
  }

  assert {
    condition     = length(aws_organizations_policy_attachment.this) == 4
    error_message = "Each configured policy target must create an attachment."
  }
}

mock_provider "aws" {}

run "restricted_deployment_roles" {
  command = apply

  variables {
    name_prefix = "macp-dev"

    trusted_aws_principal_arns = [
      "arn:aws:iam::111111111111:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_PlatformEngineer_0123456789abcdef"
    ]

    github_oidc_provider_arn = "arn:aws:iam::111111111111:oidc-provider/token.actions.githubusercontent.com"
    github_subjects = [
      "repo:example/terraform-infrastructure-projects:environment:development"
    ]

    external_id          = "macp-deployment"
    require_mfa          = true
    max_session_duration = 3600
  }

  override_resource {
    target = aws_iam_policy.deployment_boundary

    values = {
      arn = "arn:aws:iam::111111111111:policy/macp-dev-deployment-boundary"
    }
  }

  assert {
    condition     = aws_iam_role.plan.name == "macp-dev-terraform-plan"
    error_message = "The plan role must use the expected name."
  }

  assert {
    condition     = aws_iam_role.apply.name == "macp-dev-terraform-apply"
    error_message = "The apply role must use the expected name."
  }

  assert {
    condition = (
      aws_iam_role.plan.max_session_duration == 3600 &&
      aws_iam_role.apply.max_session_duration == 3600
    )
    error_message = "Both roles must use the configured session duration."
  }

  assert {
    condition = (
      aws_iam_role.plan.permissions_boundary == aws_iam_policy.deployment_boundary.arn &&
      aws_iam_role.apply.permissions_boundary == aws_iam_policy.deployment_boundary.arn
    )
    error_message = "Both deployment roles must use the permissions boundary."
  }

  assert {
    condition = strcontains(
      aws_iam_role.plan.assume_role_policy,
      "AWSReservedSSO_PlatformEngineer_0123456789abcdef"
    )
    error_message = "The trust policy must include the approved IAM Identity Center role."
  }

  assert {
    condition = (
      strcontains(aws_iam_role.apply.assume_role_policy, "sts:ExternalId") &&
      strcontains(aws_iam_role.apply.assume_role_policy, "aws:MultiFactorAuthPresent")
    )
    error_message = "AWS principal trust must enforce the configured external ID and MFA."
  }

  assert {
    condition = (
      strcontains(aws_iam_role.plan.assume_role_policy, "token.actions.githubusercontent.com") &&
      strcontains(aws_iam_role.plan.assume_role_policy, "repo:example/terraform-infrastructure-projects:environment:development")
    )
    error_message = "The trust policy must restrict GitHub OIDC to approved subjects."
  }

  assert {
    condition = !strcontains(
      aws_iam_role.plan.assume_role_policy,
      "arn:aws:iam::999999999999:root"
    )
    error_message = "An unapproved principal must not appear in the trust policy."
  }

  assert {
    condition = (
      length(aws_iam_role_policy_attachment.plan) == 1 &&
      length(aws_iam_role_policy_attachment.apply) == 1
    )
    error_message = "The plan and apply roles must each receive their configured managed policy."
  }

  assert {
    condition = (
      strcontains(aws_iam_policy.deployment_boundary.policy, "iam:CreateAccessKey") &&
      strcontains(aws_iam_policy.deployment_boundary.policy, "organizations:LeaveOrganization") &&
      strcontains(aws_iam_policy.deployment_boundary.policy, "account:CloseAccount")
    )
    error_message = "The boundary must deny long-lived credentials, organization exit, and account closure."
  }
}

run "rejects_incomplete_github_trust" {
  command = plan

  variables {
    name_prefix              = "macp-invalid"
    github_oidc_provider_arn = "arn:aws:iam::111111111111:oidc-provider/token.actions.githubusercontent.com"
    github_subjects          = []
  }

  expect_failures = [
    aws_iam_role.plan,
    aws_iam_role.apply
  ]
}

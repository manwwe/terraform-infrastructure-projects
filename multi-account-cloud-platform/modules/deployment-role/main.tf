locals {
  aws_trust_statement = length(var.trusted_aws_principal_arns) == 0 ? [] : [
    merge(
      {
        Sid    = "ApprovedAwsPrincipals"
        Effect = "Allow"
        Principal = {
          AWS = sort(tolist(var.trusted_aws_principal_arns))
        }
        Action = "sts:AssumeRole"
      },
      length(merge(
        var.external_id == null ? {} : {
          StringEquals = {
            "sts:ExternalId" = var.external_id
          }
        },
        var.require_mfa ? {
          Bool = {
            "aws:MultiFactorAuthPresent" = "true"
          }
        } : {}
        )) == 0 ? {} : {
        Condition = merge(
          var.external_id == null ? {} : {
            StringEquals = {
              "sts:ExternalId" = var.external_id
            }
          },
          var.require_mfa ? {
            Bool = {
              "aws:MultiFactorAuthPresent" = "true"
            }
          } : {}
        )
      }
    )
  ]

  github_trust_statement = var.github_oidc_provider_arn == null ? [] : [
    {
      Sid    = "ApprovedGitHubWorkflows"
      Effect = "Allow"
      Principal = {
        Federated = var.github_oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = sort(tolist(var.github_subjects))
        }
      }
    }
  ]

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = concat(local.aws_trust_statement, local.github_trust_statement)
  })

  common_tags = merge(var.tags, {
    ManagedBy = "Terraform"
  })
}

resource "aws_iam_policy" "deployment_boundary" {
  name        = "${var.name_prefix}-deployment-boundary"
  description = "Permissions boundary for Terraform deployment roles"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowAccountAdministration"
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
      },
      {
        Sid    = "DenyLongLivedIamUsers"
        Effect = "Deny"
        Action = [
          "iam:CreateAccessKey",
          "iam:CreateLoginProfile",
          "iam:CreateUser"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyAccountAndOrganizationExit"
        Effect = "Deny"
        Action = [
          "account:CloseAccount",
          "organizations:LeaveOrganization"
        ]
        Resource = "*"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role" "plan" {
  name                 = "${var.name_prefix}-terraform-plan"
  description          = "Read-only role used to create Terraform plans"
  assume_role_policy   = local.assume_role_policy
  max_session_duration = var.max_session_duration
  permissions_boundary = aws_iam_policy.deployment_boundary.arn

  tags = merge(local.common_tags, {
    Purpose = "TerraformPlan"
  })

  lifecycle {
    precondition {
      condition = (
        length(var.trusted_aws_principal_arns) > 0 ||
        (
          var.github_oidc_provider_arn != null &&
          length(var.github_subjects) > 0
        )
      )
      error_message = "At least one AWS principal or complete GitHub OIDC trust configuration is required."
    }

    precondition {
      condition = (
        (var.github_oidc_provider_arn == null) ==
        (length(var.github_subjects) == 0)
      )
      error_message = "github_oidc_provider_arn and github_subjects must be configured together."
    }
  }
}

resource "aws_iam_role" "apply" {
  name                 = "${var.name_prefix}-terraform-apply"
  description          = "Privileged role used to apply reviewed Terraform plans"
  assume_role_policy   = local.assume_role_policy
  max_session_duration = var.max_session_duration
  permissions_boundary = aws_iam_policy.deployment_boundary.arn

  tags = merge(local.common_tags, {
    Purpose = "TerraformApply"
  })

  lifecycle {
    precondition {
      condition = (
        length(var.trusted_aws_principal_arns) > 0 ||
        (
          var.github_oidc_provider_arn != null &&
          length(var.github_subjects) > 0
        )
      )
      error_message = "At least one AWS principal or complete GitHub OIDC trust configuration is required."
    }

    precondition {
      condition = (
        (var.github_oidc_provider_arn == null) ==
        (length(var.github_subjects) == 0)
      )
      error_message = "github_oidc_provider_arn and github_subjects must be configured together."
    }
  }
}

resource "aws_iam_role_policy_attachment" "plan" {
  for_each = var.plan_policy_arns

  role       = aws_iam_role.plan.name
  policy_arn = each.value
}

resource "aws_iam_role_policy_attachment" "apply" {
  for_each = var.apply_policy_arns

  role       = aws_iam_role.apply.name
  policy_arn = each.value
}

locals {
  tags = {
    Project     = "multi-account-cloud-platform"
    Environment = "shared"
    Owner       = var.owner
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
  tags            = local.tags
}

module "deployment_roles" {
  source = "../../modules/deployment-role"

  name_prefix                = "macp-shared"
  trusted_aws_principal_arns = ["arn:aws:iam::${var.management_account_id}:root"]
  github_oidc_provider_arn   = aws_iam_openid_connect_provider.github.arn
  github_subjects = [
    "repo:${var.github_repository}:pull_request",
    "repo:${var.github_repository}:ref:refs/heads/main"
  ]
  require_mfa = false
  tags        = local.tags
}

resource "aws_iam_policy" "remote_state" {
  name        = "macp-shared-terraform-state-access"
  description = "Read and lock access to the existing Terraform state backend"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket", "s3:GetBucketLocation"]
        Resource = "arn:aws:s3:::${var.state_bucket_name}"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "arn:aws:s3:::${var.state_bucket_name}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt", "kms:DescribeKey", "kms:Encrypt", "kms:GenerateDataKey"]
        Resource = var.state_kms_key_arn
      }
    ]
  })
  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "state_plan" {
  role       = module.deployment_roles.plan_role_name
  policy_arn = aws_iam_policy.remote_state.arn
}

resource "aws_iam_role_policy_attachment" "state_apply" {
  role       = module.deployment_roles.apply_role_name
  policy_arn = aws_iam_policy.remote_state.arn
}

module "private_dns" {
  count  = var.private_dns == null ? 0 : 1
  source = "../../modules/private-dns"

  zone_name        = var.private_dns.zone_name
  vpc_associations = var.private_dns.vpc_associations
  tags             = local.tags
}

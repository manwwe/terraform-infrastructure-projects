resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
  tags            = var.tags
}

module "roles" {
  source = "../deployment-role"

  name_prefix                = var.name_prefix
  trusted_aws_principal_arns = var.trusted_aws_principal_arns
  github_oidc_provider_arn   = aws_iam_openid_connect_provider.github.arn
  github_subjects = [
    "repo:${var.github_repository}:pull_request",
    "repo:${var.github_repository}:environment:${var.github_environment}"
  ]
  tags = var.tags
}

resource "aws_iam_policy" "state" {
  name = "${var.name_prefix}-terraform-state-access"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["s3:GetBucketLocation", "s3:ListBucket"], Resource = "arn:aws:s3:::${var.state_bucket_name}" },
      { Effect = "Allow", Action = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"], Resource = "arn:aws:s3:::${var.state_bucket_name}/*" },
      { Effect = "Allow", Action = ["kms:Decrypt", "kms:DescribeKey", "kms:Encrypt", "kms:GenerateDataKey"], Resource = var.state_kms_key_arn }
    ]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "plan_state" {
  role       = module.roles.plan_role_name
  policy_arn = aws_iam_policy.state.arn
}

resource "aws_iam_role_policy_attachment" "apply_state" {
  role       = module.roles.apply_role_name
  policy_arn = aws_iam_policy.state.arn
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_partition" "current" {}

data "aws_iam_policy_document" "cloudwatch_logs" {
  count = length(var.cloudwatch_log_group_arns) > 0 ? 1 : 0

  statement {
    sid       = "DescribeLogStreams"
    effect    = "Allow"
    actions   = ["logs:DescribeLogStreams"]
    resources = sort(tolist(var.cloudwatch_log_group_arns))
  }

  statement {
    sid    = "WriteLogStreams"
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      for arn in sort(tolist(var.cloudwatch_log_group_arns)) :
      "${arn}:log-stream:*"
    ]
  }
}

data "aws_iam_policy_document" "secrets_manager" {
  count = length(var.secret_arns) > 0 ? 1 : 0

  statement {
    sid    = "ReadApplicationSecrets"
    effect = "Allow"

    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
    ]

    resources = sort(tolist(var.secret_arns))
  }
}

resource "aws_iam_role" "application" {
  name               = "${var.name_prefix}-application-role"
  description        = "IAM role used by the application EC2 instances."
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-application-role"
  })
}

resource "aws_iam_instance_profile" "application" {
  name = "${var.name_prefix}-application-profile"
  role = aws_iam_role.application.name

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-application-profile"
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role = aws_iam_role.application.name

  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy" "cloudwatch_logs" {
  count = length(var.cloudwatch_log_group_arns) > 0 ? 1 : 0

  name        = "${var.name_prefix}-cloudwatch-logs-policy"
  description = "Allows application instances to write to approved CloudWatch log groups."
  policy      = data.aws_iam_policy_document.cloudwatch_logs[0].json

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-cloudwatch-logs-policy"
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_logs" {
  count = length(var.cloudwatch_log_group_arns) > 0 ? 1 : 0

  role       = aws_iam_role.application.name
  policy_arn = aws_iam_policy.cloudwatch_logs[0].arn
}

resource "aws_iam_policy" "secrets_manager" {
  count = length(var.secret_arns) > 0 ? 1 : 0

  name        = "${var.name_prefix}-secrets-manager-policy"
  description = "Allows application instances to read approved Secrets Manager secrets."
  policy      = data.aws_iam_policy_document.secrets_manager[0].json

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-secrets-manager-policy"
  })
}

resource "aws_iam_role_policy_attachment" "secrets_manager" {
  count = length(var.secret_arns) > 0 ? 1 : 0

  role       = aws_iam_role.application.name
  policy_arn = aws_iam_policy.secrets_manager[0].arn
}

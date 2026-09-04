locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Owner       = var.owner
    ManagedBy   = "Terraform"
  }
}

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "state" {
  description             = "Encrypts Terraform state for ${var.project_name}"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [{
        Sid       = "EnableAccountAdministration"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      }],
      length(var.authorized_principal_arns) == 0 ? [] : [{
        Sid       = "AllowTerraformStateEncryption"
        Effect    = "Allow"
        Principal = { AWS = sort(tolist(var.authorized_principal_arns)) }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }]
    )
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-terraform-state"
  })

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_kms_alias" "state" {
  name          = var.kms_alias
  target_key_id = aws_kms_key.state.key_id
}

resource "aws_s3_bucket" "state" {
  bucket = var.bucket_name

  tags = merge(local.common_tags, {
    Name = var.bucket_name
  })

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_ownership_controls" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.state.arn
      sse_algorithm     = "aws:kms"
    }

    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "state" {
  bucket = aws_s3_bucket.state.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [{
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.state.arn,
          "${aws_s3_bucket.state.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }],
      length(var.authorized_principal_arns) == 0 ? [] : [
        {
          Sid       = "AllowTerraformStateBucketAccess"
          Effect    = "Allow"
          Principal = { AWS = sort(tolist(var.authorized_principal_arns)) }
          Action    = ["s3:GetBucketLocation", "s3:ListBucket"]
          Resource  = aws_s3_bucket.state.arn
        },
        {
          Sid       = "AllowTerraformStateObjectAccess"
          Effect    = "Allow"
          Principal = { AWS = sort(tolist(var.authorized_principal_arns)) }
          Action    = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"]
          Resource  = "${aws_s3_bucket.state.arn}/*"
        }
      ]
    )
  })

  depends_on = [aws_s3_bucket_public_access_block.state]
}

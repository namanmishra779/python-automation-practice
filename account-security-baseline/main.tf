data "aws_caller_identity" "current" {}

locals {
  trail_bucket_name = "${var.project_name}-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
  trail_arn         = "arn:aws:cloudtrail:${var.aws_region}:${data.aws_caller_identity.current.account_id}:trail/${var.trail_name}"
}

resource "aws_s3_bucket" "cloudtrail" {
  bucket = local.trail_bucket_name
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  bucket                  = aws_s3_bucket.cloudtrail.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    id     = "expire-cloudtrail-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = var.cloudtrail_retention_days
    }
  }
}

data "aws_iam_policy_document" "cloudtrail_bucket" {
  statement {
    sid    = "CloudTrailBucketAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail.arn]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.trail_arn]
    }
  }

  statement {
    sid    = "CloudTrailWriteLogs"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.cloudtrail.arn}/cloudtrail/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.trail_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  policy = data.aws_iam_policy_document.cloudtrail_bucket.json
}

resource "aws_cloudtrail" "baseline" {
  name                          = var.trail_name
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  s3_key_prefix                 = "cloudtrail"
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  enable_logging                = true

  depends_on = [aws_s3_bucket_policy.cloudtrail]
}

resource "aws_secretsmanager_secret" "app_db" {
  name                    = var.secret_name
  recovery_window_in_days = var.secret_recovery_days
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*"]
    }
  }
}

resource "aws_iam_role" "app" {
  name               = "${var.project_name}-app"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

data "aws_iam_policy_document" "app_secret" {
  statement {
    sid       = "ReadOnlyTheApplicationSecret"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.app_db.arn]
  }
}

resource "aws_iam_role_policy" "app_secret" {
  name   = "read-one-secret"
  role   = aws_iam_role.app.id
  policy = data.aws_iam_policy_document.app_secret.json
}

resource "aws_iam_instance_profile" "app" {
  name = "${var.project_name}-app"
  role = aws_iam_role.app.name
}

resource "aws_iam_group" "developers" {
  name = "${var.project_name}-developers"
}

data "aws_iam_policy_document" "developers" {
  statement {
    sid       = "DescribeCompute"
    effect    = "Allow"
    actions   = ["ec2:Describe*"]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = length(var.developer_s3_bucket_arns) == 0 ? [] : [true]

    content {
      sid       = "ListApprovedBuckets"
      effect    = "Allow"
      actions   = ["s3:ListBucket"]
      resources = var.developer_s3_bucket_arns
    }
  }

  dynamic "statement" {
    for_each = length(var.developer_s3_bucket_arns) == 0 ? [] : [true]

    content {
      sid       = "ReadApprovedBucketObjects"
      effect    = "Allow"
      actions   = ["s3:GetObject"]
      resources = [for bucket_arn in var.developer_s3_bucket_arns : "${bucket_arn}/*"]
    }
  }
}

resource "aws_iam_group_policy" "developers" {
  name   = "${var.project_name}-read-only"
  group  = aws_iam_group.developers.name
  policy = data.aws_iam_policy_document.developers.json
}

resource "aws_iam_user" "example" {
  count = var.create_example_iam_user ? 1 : 0
  name  = var.example_iam_user_name
}

resource "aws_iam_user_group_membership" "example" {
  count  = var.create_example_iam_user ? 1 : 0
  user   = aws_iam_user.example[0].name
  groups = [aws_iam_group.developers.name]
}

resource "aws_guardduty_detector" "baseline" {
  count  = var.enable_guardduty ? 1 : 0
  enable = true
}

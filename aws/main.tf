terraform {
  required_version = ">= 1.0.0"
}

provider "aws" {
  region  = var.region
  profile = var.profile
}

## CloudWatch metric stream
resource "aws_cloudwatch_metric_stream" "datadog" {
  name          = "datadog-metric-stream"
  role_arn      = aws_iam_role.datadog_metric_stream.arn
  firehose_arn  = aws_kinesis_firehose_delivery_stream.datadog.arn
  output_format = "opentelemetry0.7"

  dynamic "include_filter" {
    for_each = var.datadog_metric_stream_namespace_list
    iterator = item

    content {
      namespace = item.value
    }
  }
}

resource "aws_iam_role" "datadog_metric_stream" {
  name               = "datadog_metric_stream_role"
  assume_role_policy = data.aws_iam_policy_document.datadog_metric_stream_assume.json
}

data "aws_iam_policy_document" "datadog_metric_stream_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["streams.metrics.cloudwatch.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role_policy" "datadog_metric_stream_firehose" {
  name   = "datadog_metric_stream_firehose_role_policy"
  policy = data.aws_iam_policy_document.datadog_metric_stream_firehose.json
  role   = aws_iam_role.datadog_metric_stream.id
}

data "aws_iam_policy_document" "datadog_metric_stream_firehose" {
  statement {
    actions = [
      "firehose:PutRecord",
      "firehose:PutRecordBatch",
    ]

    resources = [aws_kinesis_firehose_delivery_stream.datadog.arn]
  }
}

## Kinesis Firehose
resource "aws_kinesis_firehose_delivery_stream" "datadog" {
  name        = "datadog-metric-delivery-stream"
  destination = "http_endpoint"

  http_endpoint_configuration {
    name               = "Datadog"
    access_key         = var.datadog_api_key
    buffering_interval = 60 # seconds
    buffering_size     = 4  # MB
    retry_duration     = 60 # seconds
    role_arn           = aws_iam_role.datadog_firehose.arn
    s3_backup_mode     = "FailedDataOnly"
    url                = var.datadog_firehose_endpoint

    cloudwatch_logging_options {
      enabled = false
    }

    processing_configuration {
      enabled = false
    }

    request_configuration {
      content_encoding = "GZIP"
    }
  }

  s3_configuration {
    bucket_arn      = aws_s3_bucket.datadog_firehose_backup.arn
    buffer_interval = 300 # seconds
    buffer_size     = 5   # MB
    prefix          = "metrics/"
    role_arn        = aws_iam_role.datadog_firehose.arn

    cloudwatch_logging_options {
      enabled = false
    }
  }

  server_side_encryption {
    enabled = false
  }
}

resource "aws_iam_role" "datadog_firehose" {
  name               = "datadog_firehose_role"
  assume_role_policy = data.aws_iam_policy_document.datadog_firehose_assume.json
}

data "aws_iam_policy_document" "datadog_firehose_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["firehose.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role_policy" "datadog_firehose_s3_backup" {
  name   = "datadog_firehose_s3_backup_role_policy"
  policy = data.aws_iam_policy_document.datadog_firehose_s3_backup.json
  role   = aws_iam_role.datadog_firehose.id
}

data "aws_iam_policy_document" "datadog_firehose_s3_backup" {
  statement {
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
    ]

    resources = [aws_s3_bucket.datadog_firehose_backup.arn]
  }

  statement {
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetObject",
      "s3:PutObject",
    ]

    resources = ["${aws_s3_bucket.datadog_firehose_backup.arn}/*"]
  }
}

## Kinesis Firehose - S3 error/backup bucket
resource "aws_s3_bucket" "datadog_firehose_backup" {
  bucket = "${var.prefix}-datadog-firehose-backup"
  acl    = "private"

  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "datadog_firehose_backup" {
  bucket                  = aws_s3_bucket.datadog_firehose_backup.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

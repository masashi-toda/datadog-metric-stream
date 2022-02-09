output "aws_cloudwatch_metric_stream_name" {
  value = aws_cloudwatch_metric_stream.datadog.name
}

output "aws_kinesis_firehose_delivery_stream_name" {
  value = aws_kinesis_firehose_delivery_stream.datadog.name
}

output "aws_kinesis_firehose_s3_bucket" {
  value = aws_s3_bucket.datadog_firehose_backup.bucket
}

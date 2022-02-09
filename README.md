# datadog-metric-stream

Monitor CloudWatch metrics from your AWS service By DataDog.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) (>= 1.0.0)


## Project structure

- aws
    - The terraform scripts for deploying a datadog metric stream on AWS.

## Setup local environment

```sh
$ cp .env.template .env.local
```

Edit `.env.local` variables for your environment:
- `PREFIX`: Set as Kinesis Firehose delivery stream bucket suffix name.
- `AWS_PROFILE`: Your AWS account profile.
- `AWS_REGION`: Your AWS region name.
- `DATADOG_API_KEY`: Your Datadog account API key.
- `DATADOG_METRICS_NAMESPACE_LIST`: List of CloudWatch metric AWS namespaces for delivery onto Datadog.
- `DATADOG_FIREHOSE_ENDPOINT`: The HTTPS endpoint for delivery of metrics payloads into Datadog.

## Provisioning AWS Infrastructure with Terraform

```sh
$ make run-terraform-init-aws
$ make run-terraform-plan-aws
$ make run-terraform-apply-aws
```

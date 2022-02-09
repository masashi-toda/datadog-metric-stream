# Makefile for datadog-metrics-stream
.DEFAULT_GOAL := help

# Load env file
ENV ?= local
env ?= .env.$(ENV)
include $(env)

# -----------------------------------------------------------------
#    ENV VARIABLE
# -----------------------------------------------------------------
NAME = datadog-metrics-stream

# Terraform settings
TFM_VARS = -var 'prefix=$(PREFIX)' \
           -var 'profile=$(AWS_PROFILE)' \
           -var 'region=$(AWS_REGION)' \
           -var 'datadog_api_key=$(DATADOG_API_KEY)' \
           -var 'datadog_metric_stream_namespace_list=$(DATADOG_METRIC_NAMESPACE_LIST)' \
           -var 'datadog_firehose_endpoint=$(DATADOG_FIREHOSE_ENDPOINT)'

# -----------------------------------------------------------------
#    Main targets
# -----------------------------------------------------------------

.PHONY: env
env: ## Print useful environment variables to stdout
	@echo $(env)
	@echo $(TFM_VARS)

.PHONY: help
help: env
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' Makefile | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

# -----------------------------------------------------------------
#    Terraform targets
# -----------------------------------------------------------------

.PHONY: run-terraform-init-aws
run-terraform-init-aws: ## Run terraform init command for your AWS service
	@cd aws && terraform init $(TFM_VARS) && cd ..

.PHONY: run-terraform-plan-aws
run-terraform-plan-aws: ## Run terraform plan command for your AWS service
	@cd aws && terraform plan $(TFM_VARS) && cd ..

.PHONY: run-terraform-apply-aws
run-terraform-apply-aws: ## Run terraform apply command for your AWS service
	@cd aws && terraform apply $(TFM_VARS) && cd ..

.PHONY: run-terraform-destroy-aws
run-terraform-destroy-aws: ## Run terraform destroy command for your AWS service
	@cd aws && terraform destroy $(TFM_VARS) && cd ..

TF_AWS_REGION ?= us-east-2
TF_STATE_BUCKET ?= terraform-state-topleft-llm
TF_STATE_PREFIX ?= $(env)/default.tfstate


TF_DIR ?= terraform

VAR_FILE ?= config/env/$(env).tfvars


.PHONY: terraform_installed
terraform_installed:
	$(if $(shell command -v terraform 2> /dev/null),,$(error "terraform is not installed; install terraform: https://developer.hashicorp.com/terraform/downloads"))

.PHONY: tflint_installed
tflint_installed:
	$(if $(shell command -v tflint 2> /dev/null),,$(error "tflint is not installed; install tflint: https://github.com/terraform-linters/tflint#installation"))

### Terraform targets
.PHONY: init_terraform
init_terraform: fmt_terraform
	@terraform \
		-chdir=$(TF_DIR) init \
		-backend-config="bucket=$(TF_STATE_BUCKET)" \
		-backend-config="key=$(TF_STATE_PREFIX)" \
		-backend-config="region=$(TF_AWS_REGION)" \
		-reconfigure \
		-upgrade
	@echo "Terraform initialized for env: $(env)"


.PHONY: plan_terraform
plan_terraform: fmt_terraform lint_terraform init_terraform
	@terraform -chdir=$(TF_DIR) plan

.PHONY: apply_terraform
apply_terraform: fmt_terraform lint_terraform init_terraform
	@terraform -chdir=$(TF_DIR) apply -auto-approve

.PHONY: destroy_terraform
destroy_terraform: fmt_terraform
	@terraform -chdir=$(TF_DIR) destroy -auto-approve

.PHONY: fmt_terraform
fmt_terraform:
	@terraform fmt $(TF_DIR)

.PHONY: lint_terraform
lint_terraform: tflint_installed
	@tflint --chdir $(TF_DIR)


.PHONY: init_dev
init_dev: env:=dev
init_dev: init_terraform

.PHONY: plan_dev
plan_dev: env:=dev
plan_dev: init_dev plan_terraform

.PHONY: apply_dev
apply_dev: env:=dev
apply_dev: init_dev apply_terraform

.PHONY: destroy_dev
destroy_dev: env:=dev
destroy_dev: init_dev destroy_terraform
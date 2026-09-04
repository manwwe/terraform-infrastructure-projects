SHELL := /bin/bash

TERRAFORM_DIRS := $(shell find . -type f -name '*.tf' -exec dirname {} \; | sort -u)
TEST_DIRS := $(shell find . -type f -name '*.tftest.hcl' -exec dirname {} \; | sort -u)

.PHONY: fmt validate test lint security check

fmt:
	terraform fmt -check -recursive .

validate:
	@for directory in $(TERRAFORM_DIRS); do \
		echo "Validating $$directory"; \
		terraform -chdir=$$directory init -backend=false -input=false; \
		terraform -chdir=$$directory validate; \
	done

test:
	@for directory in $(TEST_DIRS); do \
		echo "Testing $$directory"; \
		terraform -chdir=$$directory test; \
	done

lint:
	tflint --recursive

security:
	trivy config .

check: fmt validate test lint security

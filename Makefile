.PHONY: fmt validate check

fmt:
	terraform fmt -recursive

validate:
	terraform -chdir=infra/aws init -backend=false
	terraform -chdir=infra/aws validate

check: fmt validate

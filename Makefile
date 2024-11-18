# this is kinda slow. It would be faster to dump the whole output and then use jq...
define GetFromTf
$(shell cd terraform/$(1) && terraform output --raw $(2))
endef


COMMIT := $(shell git rev-parse --short HEAD)
PROD_PROJECT_ID = $(call GetFromTf,prod,project_id)
PROD_TAG_NAMESPACE = $(call GetFromTf,prod,tag_namespace)
PROD_BUILD_SA = $(call GetFromTf,prod,build_sa)
PROD_BILLING_ACCOUNT = $(call GetFromTf,prod,billing_account)
PROD_ORG_ID = $(call GetFromTf,prod,org_id)
PROD_TERRAFORM_SA = $(call GetFromTf,prod,terraform_sa)

BETA_PROJECT_ID = $(call GetFromTf,beta,project_id)
BETA_TAG_NAMESPACE = $(call GetFromTf,beta,tag_namespace)
BETA_BUILD_SA = $(call GetFromTf,beta,build_sa)
BETA_BILLING_ACCOUNT = $(call GetFromTf,beta,billing_account)
BETA_ORG_ID = $(call GetFromTf,beta,org_id)
BETA_TERRAFORM_SA = $(call GetFromTf,beta,terraform_sa)

JSFILES = build/dist/index.js build/dist/puppet.js

bootstrap_prod :
	cd terraform/prod && terraform init && terraform apply --var bootstrap=true --var billing_account=$(BILLING_ACCOUNT) --var org_id=$(ORG_ID) --var terraform_sa=$(TERRAFORM_SA)
	git add terraform/prod/backend.tf
	cd terraform/prod && terraform init

bootstrap_beta :
	cd terraform/beta && terraform init && terraform apply --var bootstrap=true --var billing_account=$(BILLING_ACCOUNT) --var org_id=$(ORG_ID) --var terraform_sa=$(TERRAFORM_SA)
	git add terraform/beta/backend.tf
	cd terraform/beta && terraform init

node : $(JSFILES)
$(JSFILES) : build/dist/%.js: src/%.ts package.json package-lock.json
	npm install
	npm run build

image_deps :  $(JSFILES) Dockerfile package.json package-lock.json cloudbuild.yaml
	mkdir -p build/docker
	cp -R Dockerfile cloudbuild.yaml package.json package-lock.json build/dist build/docker/

#This is too slow and rebuilds even when nothing has changed.
build_prod: image_deps
	cd build/docker && gcloud builds submit --project "$(PROD_PROJECT_ID)" --substitutions=REPO_FULL_NAME=$(PROD_TAG_NAMESPACE),SHORT_SHA=$(COMMIT) --impersonate-service-account="$(PROD_BUILD_SA)"

build_beta: image_deps
	cd build/docker && gcloud builds submit --project "$(BETA_PROJECT_ID)" --substitutions=REPO_FULL_NAME=$(BETA_TAG_NAMESPACE),SHORT_SHA=$(COMMIT) --impersonate-service-account="$(BETA_BUILD_SA)"

deploy_prod:
	cd terraform/prod && terraform init && terraform apply --auto-approve --var billing_account=$(PROD_BILLING_ACCOUNT) --var org_id=$(PROD_ORG_ID) --var "cloudrundemo_image_tag=$(PROD_TAG_NAMESPACE)/cloudrundemo-image:$(COMMIT)" --var terraform_sa=$(PROD_TERRAFORM_SA)

deploy_beta:
	cd terraform/prod && terraform init && terraform apply --auto-approve --var billing_account=$(BETA_BILLING_ACCOUNT) --var org_id=$(BETA_ORG_ID) --var "cloudrundemo_image_tag=$(BETA_TAG_NAMESPACE)/cloudrundemo-image:$(COMMIT)" --var terraform_sa=$(BETA_TERRAFORM_SA)
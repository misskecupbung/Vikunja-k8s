SHELL := /bin/bash

ENV ?= dev
TF_VAR_FILE ?= environments/$(ENV).tfvars
BACKEND_FILE ?= environments/backend-$(ENV).hcl

TERRAFORM := terraform
HELM := helm
KUBECONFORM := kubeconform
CHART := charts/vikunja

.PHONY: init plan apply destroy lint fmt helm-template kube-validate validate all

init:
	$(TERRAFORM) init -backend-config="$(BACKEND_FILE)" -reconfigure

plan:
	$(TERRAFORM) plan -var-file=$(TF_VAR_FILE)

apply:
	$(TERRAFORM) apply -auto-approve -var-file=$(TF_VAR_FILE)

destroy:
	$(TERRAFORM) destroy -auto-approve -var-file=$(TF_VAR_FILE)

lint: fmt helm-template kube-validate

fmt:
	$(TERRAFORM) fmt -recursive

helm-template:
	$(HELM) dependency update $(CHART) || true
	$(HELM) template vikunja $(CHART) --values $(CHART)/values.yaml > /tmp/vikunja.rendered.yaml

kube-validate: helm-template
	command -v $(KUBECONFORM) >/dev/null 2>&1 || { echo "kubeconform not installed"; exit 1; }
	$(KUBECONFORM) -ignore-missing-schemas -schema-location default -summary /tmp/vikunja.rendered.yaml

validate: lint plan

all: init apply

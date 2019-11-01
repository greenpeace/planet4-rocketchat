SHELL := /bin/bash

.EXPORT_ALL_VARIABLES:

HELM_RELEASE := p4-rocketchat
NAMESPACE ?= rocketchat

CHART_NAME ?= stable/rocketchat
CHART_VERSION ?= 1.1.5
DEV_CLUSTER ?= p4-development
DEV_PROJECT ?= planet-4-151612
DEV_ZONE ?= us-central1-a

BACKUP_BUCKET := $(HELM_RELEASE)-backup

connect:
	gcloud config set project $(DEV_PROJECT)
	gcloud container clusters get-credentials $(DEV_CLUSTER) --zone $(DEV_ZONE) --project $(DEV_PROJECT)

deploy: connect
ifndef CI
	$(error Please commit and push, this is intended to be run in a CI environment)
endif
ifndef CI_MONGO_DB_USERNAME
	$(error CI_MONGO_DB_USERNAME is not set)
endif
ifndef CI_MONGO_DB_PASSWORD
	$(error CI_MONGO_DB_PASSWORD is not set)
endif
ifndef CI_MONGO_DB_ROOT_PASSWORD
	$(error CI_MONGO_DB_ROOT_PASSWORD is not set)
endif
	sed -i -e "s/CI_MONGO_DB_USERNAME/${CI_MONGO_DB_USERNAME}/g" values.yaml
	sed -i -e "s/CI_MONGO_DB_PASSWORD/${CI_MONGO_DB_PASSWORD}/g" values.yaml
	sed -i -e "s/CI_MONGO_DB_ROOT_PASSWORD/${CI_MONGO_DB_ROOT_PASSWORD}/g" values.yaml
	helm init --client-only
	helm repo update
	helm upgrade --install --force --wait $(HELM_RELEASE) \
		--namespace=$(NAMESPACE) \
		--version $(CHART_VERSION) \
		-f values.yaml \
		$(CHART_NAME)

bucket:
	gsutil ls "gs://$(BACKUP_BUCKET)" || { \
		gsutil mb "gs://$(BACKUP_BUCKET)"; \
		gsutil lifecycle set lifecycle.json "gs://$(BACKUP_BUCKET)"; \
	}

backup: bucket connect
	./backup.sh

lint:
	@find . -type f -name '*.yml' | xargs yamllint
	@find . -type f -name '*.yaml' | xargs yamllint
	@circleci config validate

history:
	helm history $(HELM_RELEASE) --max=5

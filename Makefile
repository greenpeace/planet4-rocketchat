HELM_RELEASE := p4-rocketchat
NAMESPACE ?= rocketchat

CHART_NAME ?= stable/rocketchat
CHART_VERSION ?= 1.1.2
DEV_CLUSTER ?= p4-development
DEV_PROJECT ?= planet-4-151612
DEV_ZONE ?= us-central1-a


fnord:
ifndef CI
	$(error Please commit and push, this is intended to be run in a CI environment)
endif
	sed -i -e "s/CI_MONGO_DB_USERNAME/${CI_MONGO_DB_USERNAME}/g" values.yaml
	sed -i -e "s/CI_MONGO_DB_PASSWORD/${CI_MONGO_DB_PASSWORD}/g" values.yaml
	sed -i -e "s/CI_MONGO_DB_ROOT_PASSWORD/${CI_MONGO_DB_ROOT_PASSWORD}/g" values.yaml
	gcloud config set project $(DEV_PROJECT)
	gcloud container clusters get-credentials $(DEV_CLUSTER) --zone $(DEV_ZONE) --project $(DEV_PROJECT)
	helm init --client-only
	helm repo update
	helm upgrade --install --force --wait $(HELM_RELEASE) \
		--namespace=$(NAMESPACE) \
		--version $(CHART_VERSION) \
		-f values.yaml \
		$(CHART_NAME)

lint:
	@find . -type f -name '*.yml' | xargs yamllint
	@find . -type f -name '*.yaml' | xargs yamllint

history:
	helm history traefik --max=5

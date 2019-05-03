HELM_RELEASE := p4-rocketchat
NAMESPACE ?= rocketchat

CHART_NAME ?= stable/rocketchat
CHART_VERSION ?= 0.3.4

fnord:
	helm upgrade --install --force --wait $(HELM_RELEASE) \
				--namespace=$(NAMESPACE) \
				--version $(CHART_VERSION) \
				-f values.yaml \
$(CHART_NAME)


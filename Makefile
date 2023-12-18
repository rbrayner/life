################# VARIABLES #################
IMAGE_NAME=rbrayner/life

GREEN  := $(shell tput -Txterm setaf 2)
CYAN   := $(shell tput -Txterm setaf 6)
RESET  := $(shell tput -Txterm sgr0)



################# IMPORTS #################
ifneq ("$(wildcard .env)","")
	include .env
	export
endif



################# FUNCTIONS #################
define check_version
	@if [ -z "$(version)" ]; then \
		echo "Error: version parameter is required."; \
		exit 1; \
	fi
endef



################# MAIN TARGETS #################
all-k8s: ## Run k8s deployment
	@$(call check_version)
	@$(MAKE) start-cluster
	@$(MAKE) build-and-push version=$(version)
	@$(MAKE) create-private-registry-secret
	@$(MAKE) deploy version=$(version)

wipe: ## Wipe the clusters and containers
	@$(MAKE) down
	@$(MAKE) stop-cluster

help: ## Print this help
	@echo "$(CYAN)Available targets:$(RESET)"
	@awk -F':.*##' '/^[a-zA-Z0-9_-]+:.*?##/ {printf "  $(GREEN)%-30s$(RESET)  %s\n", $$1, $$2}' Makefile | sort



################# LOCAL DEPLOYMENT #################
up: ## Deploy the app locally
	@docker compose up --build -d
	@sleep 60 && $(MAKE) test-docker

down: ## Destroy the local deployment
	@docker compose down

test-docker: ## Test if the application is running on docker deployment
	@curl localhost:3000/posts



################# BUILD AND PUSH #################
login: ## Login to docker hub
	@docker login -u rbrayner -p $(DOCKER_HUB_ACCESS_CODE)

build-and-push: ## Build the image and push to docker hub
	@$(call check_version)
	@$(MAKE) login
	@docker buildx create --name builder || true
	@docker buildx use builder
	@docker buildx build --platform linux/amd64,linux/arm64 -t $(IMAGE_NAME):$(version) --push .

create-private-registry-secret:
	@TOKEN=$$(curl -s -H "Content-Type: application/json" -X POST -d '{"username": "$(DOCKER_HUB_USERNAME)", "password": "$(DOCKER_HUB_ACCESS_CODE)"}' https://hub.docker.com/v2/users/login/ | jq -r .token) && \
		DOCKER_CONFIG=$$(echo "{\"auths\":{\"https://index.docker.io/v1/\":{\"username\":\"token\",\"password\":\"$$TOKEN\"}}}" | base64) && \
		export BASE64_REGISTRY_CONFIG=$$(echo $$DOCKER_CONFIG) && \
		envsubst < k8s/app/secrets.tpl > k8s/app/secrets.yml



################# KUBERNETES DEPLOY #################
deploy: ## Deploy to a kind kubernetes cluster
	@$(call check_version)
	@kubectl config use-context kind-life
	@kubectl create namespace life || true
	@envsubst < k8s/db/secrets.tpl > k8s/db/secrets.yml && \
		kubectl apply -n life -f k8s/db
	@export IMAGE_VERSION=$(version) && \
		envsubst < k8s/app/deploy.tpl > k8s/app/deploy.yml && \
		kubectl apply -n life -f k8s/app
	@kubectl wait -n life \
		--for=condition=ready pod \
		--selector=app=life \
		--timeout=120s
	@sleep 5 && $(MAKE) test-k8s

destroy: ## Destroy the application fom a k8s cluster
	@kubectl config use-context kind-life
	@kubectl delete -f k8s/app -n life --ignore-not-found=true
	@kubectl delete -f k8s/db -n life --ignore-not-found=true

test-k8s: ## Check if application is running on k8s
	@curl -H "Host: app.local" http://localhost/posts



################# KIND CLUSTER #################
install-kind-macos: ## Install kind on MacOS
	@brew install kind

install-kind-linux: ## Install kind on Ubuntu
	@curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
	@chmod +x ./kind
	@sudo mv ./kind /usr/local/bin/kind

start-cluster: ## Create the kind cluster
	@kind create cluster --config kind/cluster.yaml --name life
	@kubectl config use-context kind-life
	@$(MAKE) install-nginx-ingress-controller

install-nginx-ingress-controller: ## Installs nginx ingress controller
	@kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
	@kubectl wait --namespace ingress-nginx \
		--for=condition=ready pod \
		--selector=app.kubernetes.io/component=controller \
		--timeout=90s

stop-cluster: ## Destroy the kind cluster
	@kind delete cluster --name life

list: ## List the available clusters
	@kind get clusters


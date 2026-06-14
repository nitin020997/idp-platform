CLUSTER_NAME := idp
KIND_CONFIG  := clusters/local/kind-config.yaml
ARGOCD_NS    := argocd
ARGOCD_VERSION := stable
ARGOCD_MANIFEST := https://raw.githubusercontent.com/argoproj/argo-cd/$(ARGOCD_VERSION)/manifests/install.yaml

# Colours for readable output
BLUE  := \033[1;34m
GREEN := \033[1;32m
YELL  := \033[1;33m
RESET := \033[0m

.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this help
	@echo ""
	@echo "$(BLUE)IDP platform — local control plane$(RESET)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-18s$(RESET) %s\n", $$1, $$2}'
	@echo ""
	@echo "  Typical first run:  $(YELL)make up$(RESET)  then  $(YELL)make argocd-ui$(RESET)"
	@echo ""

.PHONY: preflight
preflight: ## Check that docker, kind and kubectl are installed
	@command -v docker  >/dev/null 2>&1 || { echo "$(YELL)docker not found$(RESET)";  exit 1; }
	@command -v kind    >/dev/null 2>&1 || { echo "$(YELL)kind not found$(RESET)";    exit 1; }
	@command -v kubectl >/dev/null 2>&1 || { echo "$(YELL)kubectl not found$(RESET)"; exit 1; }
	@docker info >/dev/null 2>&1 || { echo "$(YELL)Docker daemon is not running — start Docker Desktop$(RESET)"; exit 1; }
	@echo "$(GREEN)✓ docker, kind, kubectl present and Docker is running$(RESET)"

.PHONY: cluster-up
cluster-up: preflight ## Create the local kind cluster
	@if kind get clusters 2>/dev/null | grep -q "^$(CLUSTER_NAME)$$"; then \
		echo "$(GREEN)✓ cluster '$(CLUSTER_NAME)' already exists$(RESET)"; \
	else \
		echo "$(BLUE)Creating kind cluster '$(CLUSTER_NAME)'...$(RESET)"; \
		kind create cluster --config $(KIND_CONFIG); \
	fi
	@kubectl cluster-info --context kind-$(CLUSTER_NAME) | head -1

.PHONY: cluster-down
cluster-down: ## Delete the local kind cluster
	@kind delete cluster --name $(CLUSTER_NAME)

.PHONY: argocd-install
argocd-install: ## Install Argo CD into the cluster
	@echo "$(BLUE)Installing Argo CD ($(ARGOCD_VERSION))...$(RESET)"
	@kubectl create namespace $(ARGOCD_NS) --dry-run=client -o yaml | kubectl apply -f -
	@# server-side apply: Argo CD's CRDs exceed kubectl's 256KB client-side annotation limit
	@kubectl apply --server-side --force-conflicts -n $(ARGOCD_NS) -f $(ARGOCD_MANIFEST)
	@echo "$(BLUE)Waiting for Argo CD server to become ready...$(RESET)"
	@kubectl rollout status -n $(ARGOCD_NS) deploy/argocd-server --timeout=300s
	@echo "$(GREEN)✓ Argo CD installed$(RESET)"

.PHONY: argocd-bootstrap
argocd-bootstrap: ## Apply the root app-of-apps (Argo CD then manages platform/)
	@kubectl apply -f bootstrap/argocd/root-app.yaml
	@echo "$(GREEN)✓ root 'platform' Application applied — Argo CD now owns platform/$(RESET)"

.PHONY: up
up: cluster-up argocd-install argocd-bootstrap ## One shot: cluster + Argo CD + bootstrap
	@echo ""
	@echo "$(GREEN)Platform is up.$(RESET)  Next:"
	@echo "  $(YELL)make argocd-password$(RESET)   # get the admin password"
	@echo "  $(YELL)make argocd-ui$(RESET)         # open the Argo CD UI on https://localhost:8080"
	@echo ""

.PHONY: argocd-password
argocd-password: ## Print the initial Argo CD admin password
	@kubectl -n $(ARGOCD_NS) get secret argocd-initial-admin-secret \
		-o jsonpath="{.data.password}" | base64 -d; echo

.PHONY: argocd-ui
argocd-ui: ## Port-forward the Argo CD UI to https://localhost:8080 (user: admin)
	@echo "$(BLUE)Argo CD UI → https://localhost:8080  (user: admin)$(RESET)"
	@kubectl port-forward -n $(ARGOCD_NS) svc/argocd-server 8080:443

.PHONY: status
status: ## Show nodes, Argo CD pods and Applications
	@echo "$(BLUE)Nodes:$(RESET)";        kubectl get nodes
	@echo "$(BLUE)Argo CD pods:$(RESET)"; kubectl get pods -n $(ARGOCD_NS)
	@echo "$(BLUE)Applications:$(RESET)";  kubectl get applications -n $(ARGOCD_NS) 2>/dev/null || true

.PHONY: down
down: cluster-down ## Tear everything down (deletes the cluster)

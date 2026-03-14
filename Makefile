.PHONY: help plugin-install dep-build dep-build-test lint yamllint kubeconform lint-all test package clean all

# Default target
help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

## Install required tools (helm-unittest plugin, yamllint, kubeconform)
plugin-install: ## Install helm-unittest plugin and lint tools
	helm plugin install https://github.com/helm-unittest/helm-unittest --version "~1"
	@echo "Install yamllint: brew install yamllint"
	@echo "Install kubeconform: brew install kubeconform"

## Build chart dependencies (main chart)
dep-build: ## Build helm dependencies for main chart
	@echo "Building plat-eng-cache-package dependencies..."
	helm dependency build .
	@echo "Dependencies built successfully"

## Build chart dependencies (test wrapper)
dep-build-test: ## Build helm dependencies for test wrapper chart
	@echo "Building test chart dependencies..."
	helm dependency build tests/chart
	@echo "Test chart dependencies built successfully"

## Lint the chart with helm
lint: ## Lint the Helm chart with helm lint
	@echo "Linting plat-eng-cache-package..."
	helm lint .
	@echo ""
	@echo "Helm lint passed"

## Lint YAML files with yamllint
yamllint: ## Lint YAML files with yamllint
	@echo "Running yamllint..."
	yamllint -c .yamllint.yml .
	@echo "yamllint passed"

## Validate rendered manifests with kubeconform
kubeconform: ## Validate rendered Kubernetes manifests with kubeconform
	@echo "Running kubeconform..."
	helm template plat-eng-cache-package . | kubeconform --strict --ignore-missing-schemas
	@echo "kubeconform passed"

## Run all linting tools (helm lint + yamllint + kubeconform)
lint-all: lint yamllint kubeconform ## Run helm lint, yamllint, and kubeconform
	@echo ""
	@echo "All linting passed"

## Run helm-unittest tests
test: ## Run helm-unittest tests
	@echo "Running helm-unittest tests..."
	helm unittest tests/chart

## Package the chart into a .tgz archive
package: ## Package the chart into a versioned .tgz archive
	@echo "Packaging plat-eng-cache-package..."
	helm package .
	@echo "Package complete"

## Remove packaged .tgz archive
clean: ## Remove packaged .tgz archive and build artifacts
	@echo "Cleaning plat-eng-cache-package..."
	rm -f plat-eng-cache-package-*.tgz
	rm -rf charts/
	rm -f Chart.lock
	rm -rf tests/chart/charts/
	rm -f tests/chart/Chart.lock
	@echo "Cleanup complete"

## Run all linting and tests
all: lint-all test package ## Run lint-all, test, and package
	@echo ""
	@echo "All targets completed successfully"

# Makefile - FlumenData Python CLI Wrapper
# This is a convenience wrapper around the Python CLI
# All commands delegate to: python3 flumen <command>

.DEFAULT_GOAL := help
.PHONY: help

# Python CLI
CLI := python3 flumen

##@ General

help: ## Display this help message
	@echo "FlumenData - Lakehouse Platform"
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "Targets:\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	@echo ""
	@echo "💡 Tip: You can also use the Python CLI directly:"
	@echo "   python3 flumen --help"

##@ Initialization

init: ## Complete environment initialization
	@$(CLI) init

init-dirs: ## Initialize data directories only
	@$(CLI) init-dirs

config: ## Generate all configuration files
	@$(CLI) config

config-%: ## Generate config for specific service (e.g., make config-minio)
	@$(CLI) config --service $*

##@ Service Management

up: ## Start all services
	@$(CLI) up

up-tier%: ## Start specific tier (e.g., make up-tier0)
	@$(CLI) up --tier $*

down: ## Stop all services
	@$(CLI) down

restart: ## Restart all services
	@$(CLI) restart

##@ Monitoring

logs: ## Show logs for all services (follow mode)
	@$(CLI) logs

logs-%: ## Show logs for specific service (e.g., make logs-spark-master)
	@$(CLI) logs --service $*

ps: ## Show container status
	@$(CLI) ps

status: ## Show container status (alias for ps)
	@$(CLI) status

health: ## Check all services health
	@$(CLI) health

health-tier%: ## Check specific tier health (e.g., make health-tier0)
	@$(CLI) health --tier $*

summary: ## Show environment summary
	@$(CLI) summary

##@ Shell Access

shell-postgres: ## Open PostgreSQL shell
	@$(CLI) shell-postgres

shell-spark: ## Open Spark shell (Scala)
	@$(CLI) shell-spark

shell-pyspark: ## Open PySpark shell (Python)
	@$(CLI) shell-pyspark

shell-spark-sql: ## Open Spark SQL shell
	@$(CLI) shell-spark-sql

shell-mc: ## Open MinIO client shell
	@$(CLI) shell-mc

##@ Verification & Testing

verify-hive: ## Verify Hive Metastore setup
	@$(CLI) verify-hive

test: ## Run all tests
	@$(CLI) test

test-tier%: ## Test specific tier (e.g., make test-tier0)
	@$(CLI) test --tier $*

test-integration: ## Run integration test
	@$(CLI) test --integration

##@ Service Helpers

token-jupyterlab: ## Get JupyterLab access token
	@$(CLI) token-jupyterlab

superset-db: ## Initialize Superset database
	@$(CLI) superset-db

##@ Cleanup & Maintenance

cleanup: ## Cleanup test data
	@$(CLI) cleanup

clean: ## Stop services and remove volumes (WARNING: deletes all data)
	@$(CLI) clean

rebuild: ## Rebuild custom Docker images
	@$(CLI) rebuild

prune: ## Prune unused Docker resources
	@$(CLI) prune

##@ Python CLI

cli-help: ## Show Python CLI help
	@$(CLI) --help

version: ## Show version
	@$(CLI) --version

include Makefile.dashboard

# Catch-all: forward any unknown target to Python CLI
%:
	@$(CLI) $@

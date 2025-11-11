# Makefile - FlumenData orchestrator
# Complete Lakehouse environment initialization and management

.DEFAULT_GOAL := help
.PHONY: help init config up down restart logs clean test health

# Load environment variables
include .env
export

# Include service-specific makefiles
include makefiles/core.mk
include makefiles/postgres.mk
include makefiles/valkey.mk
include makefiles/minio.mk
include makefiles/hive.mk
include makefiles/spark.mk
include makefiles/jupyterlab.mk

# Color output
RED    := \033[0;31m
GREEN  := \033[0;32m
YELLOW := \033[0;33m
BLUE   := \033[0;34m
RESET  := \033[0m

##@ General

help: ## Display this help message
	@echo "$(BLUE)FlumenData - Open Source Lakehouse Platform$(RESET)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "Usage:\n  make $(YELLOW)<target>$(RESET)\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  $(YELLOW)%-20s$(RESET) %s\n", $$1, $$2 } /^##@/ { printf "\n$(BLUE)%s$(RESET)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Initialization

init: banner config up-tier0 init-tier0 up-tier1 init-tier1 up-tier2 init-tier2 health summary ## Complete environment initialization
	@echo "$(GREEN)✓ FlumenData initialized successfully!$(RESET)"

banner:
	@echo "$(BLUE)"
	@echo "╔═══════════════════════════════════════════════════════════════╗"
	@echo "║                                                               ║"
	@echo "║                    F L U M E N D A T A                        ║"
	@echo "║            Open Source Lakehouse Platform                     ║"
	@echo "║                                                               ║"
	@echo "╚═══════════════════════════════════════════════════════════════╝"
	@echo "$(RESET)"
	@echo ""

##@ Configuration

config: config-valkey config-minio config-hive config-spark config-jupyterlab ## Generate all configuration files
	@echo "$(GREEN)✓ All configurations generated$(RESET)"

##@ Docker Compose Management

up-tier0: ## Start Tier 0 services (Postgres, Valkey, MinIO)
	@echo "$(BLUE)[tier0] Starting foundation services...$(RESET)"
	@$(DC) -f docker-compose.tier0.yml up -d
	@echo "$(GREEN)✓ Tier 0 services started$(RESET)"

up-tier1: ## Start Tier 1 services (Hive Metastore, Spark)
	@echo "$(BLUE)[tier1] Starting data platform services...$(RESET)"
	@$(DC) -f docker-compose.tier0.yml -f docker-compose.tier1.yml up -d hive-metastore spark-master spark-worker1 spark-worker2
	@echo "$(GREEN)✓ Tier 1 services started$(RESET)"

up-tier2: config-jupyterlab ## Start Tier 2 services (JupyterLab, dbt, MLflow)
	@echo "$(BLUE)[tier2] Starting analytics & development services...$(RESET)"
	@$(DC) -f docker-compose.tier0.yml -f docker-compose.tier1.yml -f docker-compose.tier2.yml up -d jupyterlab
	@echo "$(GREEN)✓ Tier 2 services started$(RESET)"
	@echo ""
	@echo "$(YELLOW)JupyterLab:$(RESET) http://localhost:8888"
	@echo "Get token: $(YELLOW)make token-jupyterlab$(RESET)"

up: up-tier0 up-tier1 up-tier2 ## Start all services (Tier 0 + Tier 1 + Tier 2)

down: ## Stop all services
	@echo "$(YELLOW)Stopping all services...$(RESET)"
	@$(DC) -f docker-compose.tier2.yml down 2>/dev/null || true
	@$(DC) -f docker-compose.tier1.yml down 2>/dev/null || true
	@$(DC) -f docker-compose.tier0.yml down
	@echo "$(GREEN)✓ All services stopped$(RESET)"

restart: down up ## Restart all services

##@ Service Initialization

init-tier0: health-tier0 init-minio ## Initialize Tier 0 services
	@echo "$(GREEN)✓ Tier 0 initialized$(RESET)"

init-tier1: health-tier1 init-hive verify-hive ## Initialize Tier 1 services
	@echo "$(GREEN)✓ Tier 1 initialized$(RESET)"

init-tier2: health-tier2 init-jupyterlab ## Initialize Tier 2 services
	@echo "$(GREEN)✓ Tier 2 initialized$(RESET)"

##@ Health Checks

health-tier0: health-postgres health-valkey health-minio ## Check Tier 0 health
	@echo "$(GREEN)✓ Tier 0 healthy$(RESET)"

health-tier1: health-hive health-spark-master health-spark-workers ## Check Tier 1 health
	@echo "$(GREEN)✓ Tier 1 healthy$(RESET)"

health-tier2: health-jupyterlab ## Check Tier 2 health
	@echo "$(GREEN)✓ Tier 2 healthy$(RESET)"

health: health-tier0 health-tier1 health-tier2 ## Check all services health
	@echo "$(GREEN)✓ All services healthy$(RESET)"

##@ Testing

test-tier0: test-postgres test-valkey test-minio ## Test Tier 0 services
	@echo "$(GREEN)✓ Tier 0 tests passed$(RESET)"

test-tier1: test-spark test-hive ## Test Tier 1 services
	@echo "$(GREEN)✓ Tier 1 tests passed$(RESET)"

test-tier2: test-jupyterlab ## Test Tier 2 services
	@echo "$(GREEN)✓ Tier 2 tests passed$(RESET)"

test: test-tier0 test-tier1 test-tier2 ## Run all tests
	@echo "$(GREEN)✓ All tests passed$(RESET)"

test-integration: ## Test Delta Lake + Spark + Hive integration
	@echo "$(BLUE)Running integration test...$(RESET)"
	@if [ ! -f test_integration.py ]; then \
		echo "$(RED)✗ test_integration.py not found$(RESET)"; \
		exit 1; \
	fi
	@docker cp test_integration.py flumen_spark_master:/tmp/
	@$(DC) -f docker-compose.tier0.yml -f docker-compose.tier1.yml exec -T spark-master \
		/opt/spark/bin/spark-submit /tmp/test_integration.py
	@echo "$(GREEN)✓ Integration test passed$(RESET)"

##@ Data Persistence Tests

persist-tier0: persist-postgres persist-valkey persist-minio ## Test Tier 0 data persistence
	@echo "$(GREEN)✓ Tier 0 persistence verified$(RESET)"

persist-tier1: persist-spark ## Test Tier 1 data persistence
	@echo "$(GREEN)✓ Tier 1 persistence verified$(RESET)"

persist-tier2: persist-jupyterlab ## Test Tier 2 data persistence
	@echo "$(GREEN)✓ Tier 2 persistence verified$(RESET)"

persist: persist-tier0 persist-tier1 persist-tier2 ## Test all data persistence
	@echo "$(GREEN)✓ All data persistence verified$(RESET)"

##@ Cleanup

cleanup-tier0: cleanup-postgres cleanup-valkey cleanup-minio ## Cleanup Tier 0 test data
	@echo "$(GREEN)✓ Tier 0 cleanup complete$(RESET)"

cleanup-tier1: cleanup-spark ## Cleanup Tier 1 test data
	@echo "$(GREEN)✓ Tier 1 cleanup complete$(RESET)"

cleanup-tier2: cleanup-jupyterlab ## Cleanup Tier 2 test data
	@echo "$(GREEN)✓ Tier 2 cleanup complete$(RESET)"

cleanup: cleanup-tier0 cleanup-tier1 cleanup-tier2 ## Cleanup all test data
	@echo "$(GREEN)✓ All test data cleaned$(RESET)"

clean: down ## Stop services and remove volumes (WARNING: deletes all data)
	@echo "$(RED)WARNING: This will delete all data!$(RESET)"
	@printf "Are you sure? [y/N] "; \
	read REPLY; \
	case "$$REPLY" in \
		[Yy]*) \
			$(DC) -f docker-compose.tier2.yml down -v; \
			$(DC) -f docker-compose.tier1.yml down -v; \
			$(DC) -f docker-compose.tier0.yml down -v; \
			rm -rf config/*; \
			echo "$(GREEN)✓ Environment cleaned$(RESET)"; \
			;; \
		*) \
			echo "$(YELLOW)Cancelled$(RESET)"; \
			;; \
	esac

##@ Logs

logs: ## Show logs for all services
	@$(DC) -f docker-compose.tier0.yml -f docker-compose.tier1.yml -f docker-compose.tier2.yml logs -f

logs-tier0: ## Show logs for Tier 0 services
	@$(DC) -f docker-compose.tier0.yml logs -f

logs-tier1: ## Show logs for Tier 1 services
	@$(DC) -f docker-compose.tier0.yml -f docker-compose.tier1.yml logs -f hive-metastore spark-master spark-worker1 spark-worker2

logs-tier2: ## Show logs for Tier 2 services
	@$(DC) -f docker-compose.tier2.yml logs -f jupyterlab

logs-postgres: ## Show PostgreSQL logs
	@$(DC) -f docker-compose.tier0.yml logs -f postgres

logs-minio: ## Show MinIO logs
	@$(DC) -f docker-compose.tier0.yml logs -f minio

logs-spark: ## Show Spark logs
	@$(DC) -f docker-compose.tier0.yml -f docker-compose.tier1.yml logs -f spark-master spark-worker1 spark-worker2

logs-hive: ## Show Hive Metastore logs
	@$(DC) -f docker-compose.tier0.yml -f docker-compose.tier1.yml logs -f hive-metastore

##@ Service Status

ps: ## Show running containers
	@$(DC) -f docker-compose.tier0.yml -f docker-compose.tier1.yml -f docker-compose.tier2.yml ps

status: ps ## Alias for ps

summary: ## Show environment summary
	@echo ""
	@echo "$(BLUE)╔══════════════════════════════════════════════════════════════╗$(RESET)"
	@echo "$(BLUE)║              FlumenData Environment Summary                  ║$(RESET)"
	@echo "$(BLUE)╚══════════════════════════════════════════════════════════════╝$(RESET)"
	@echo ""
	@echo "$(YELLOW)Tier 0 - Foundation Services:$(RESET)"
	@echo "  • PostgreSQL    → http://localhost:5432"
	@echo "  • Valkey        → localhost:6379"
	@echo "  • MinIO API     → http://localhost:9000"
	@echo "  • MinIO Console → http://localhost:9001"
	@echo ""
	@echo "$(YELLOW)Tier 1 - Data Platform:$(RESET)"
	@echo "  • Spark Master    → http://localhost:8080"
	@echo "  • Hive Metastore  → thrift://localhost:9083"
	@echo ""
	@echo "$(YELLOW)Tier 2 - Analytics & Development:$(RESET)"
	@echo "  • JupyterLab      → http://localhost:8888 (run 'make token-jupyterlab')"
	@echo ""
	@echo "$(YELLOW)Lakehouse Architecture:$(RESET)"
	@echo "  • Catalog       : Hive Metastore (2-level: database.table)"
	@echo "  • Table Format  : Delta Lake 4.0 (with time travel)"
	@echo "  • Compute       : Apache Spark 4.0.1 (1 Master + 2 Workers)"
	@echo "  • Metadata DB   : PostgreSQL"
	@echo "  • Storage       : s3a://$(MINIO_BUCKET)/warehouse"
	@echo ""
	@echo "$(GREEN)Quick Commands:$(RESET)"
	@echo "  make logs              - View all logs"
	@echo "  make verify-hive       - Verify Hive databases"
	@echo "  make ps                - Show container status"
	@echo ""

##@ Development

shell-postgres: ## Open PostgreSQL shell
	@$(DC) -f docker-compose.tier0.yml exec postgres psql -U $(POSTGRES_USER) -d $(POSTGRES_DB)

shell-spark: ## Open Spark shell
	@$(DC) -f docker-compose.tier0.yml -f docker-compose.tier1.yml exec spark-master /opt/spark/bin/spark-shell \
		--master spark://spark-master:7077

shell-pyspark: ## Open PySpark shell
	@$(DC) -f docker-compose.tier0.yml -f docker-compose.tier1.yml exec spark-master /opt/spark/bin/pyspark \
		--master spark://spark-master:7077

shell-spark-sql: ## Open Spark SQL shell
	@$(DC) -f docker-compose.tier0.yml -f docker-compose.tier1.yml exec spark-master /opt/spark/bin/spark-sql \
		--master spark://spark-master:7077

mc: ## Open MinIO client (mc) shell
	@docker run --rm -it --network $(COMPOSE_PROJECT_NAME)_default \
		-e MC_HOST_flumen=http://$(MINIO_ROOT_USER):$(MINIO_ROOT_PASSWORD)@minio:9000 \
		minio/mc:RELEASE.2025-08-13T08-35-41Z

##@ Documentation

docs-serve: ## Serve documentation locally
	@echo "$(BLUE)Starting documentation server...$(RESET)"
	@docker run --rm -it -p 8000:8000 -v ${PWD}:/docs squidfunk/mkdocs-material
	@echo "$(GREEN)Documentation available at http://localhost:8000$(RESET)"

docs-build: ## Build documentation
	@echo "$(BLUE)Building documentation...$(RESET)"
	@docker run --rm -v ${PWD}:/docs squidfunk/mkdocs-material build
	@echo "$(GREEN)✓ Documentation built in site/$(RESET)"

##@ Advanced

rebuild: ## Rebuild all custom Docker images
	@echo "$(BLUE)Rebuilding custom Docker images...$(RESET)"
	@docker build -t flumendata/hive:standalone-metastore-4.1.0 -f docker/hive.Dockerfile .
	@docker build -t flumendata/spark:4.0.1-health -f docker/spark.Dockerfile .
	@echo "$(GREEN)✓ All custom images rebuilt$(RESET)"

reset: clean config up health ## Complete reset and reinitialize
	@echo "$(GREEN)✓ Environment reset complete$(RESET)"

validate: health test test-integration ## Full validation (health + tests + integration)
	@echo "$(GREEN)✓ Full validation passed$(RESET)"

# =============================================================================
# Airflow Makefile
# All-in-one Airflow (webserver + scheduler) using shared PostgreSQL metadata
# =============================================================================

AIRFLOW_CONFIG_DIR := config/airflow
AIRFLOW_ENV_FILE := $(AIRFLOW_CONFIG_DIR)/airflow.env
AIRFLOW_CONTAINER := airflow
COMPOSE_STACK := docker-compose.tier0.yml docker-compose.tier1.yml docker-compose.tier2.yml docker-compose.tier3.yml

# =============================================================================
# Configuration
# =============================================================================

.PHONY: config-airflow
config-airflow: $(AIRFLOW_ENV_FILE) ## Generate Airflow environment configuration
	@echo "✓ Airflow configuration ready at $(AIRFLOW_CONFIG_DIR)"

$(AIRFLOW_ENV_FILE): templates/airflow/airflow.env.tpl .env
	@echo "Rendering Airflow environment..."
	@mkdir -p $(AIRFLOW_CONFIG_DIR)
	@envsubst < $< > $@

.PHONY: clean-airflow-config
clean-airflow-config: ## Remove generated Airflow configuration
	@rm -rf $(AIRFLOW_CONFIG_DIR)
	@echo "✓ Airflow configuration cleaned"

# =============================================================================
# Initialization & Health
# =============================================================================

.PHONY: airflow-db
airflow-db: ## Ensure Airflow metadata database exists in PostgreSQL
	@echo "[airflow:init] Ensuring database $(AIRFLOW_DB_NAME) exists..."
	@EXISTS=$$(docker exec flumen_postgres psql -U $(POSTGRES_USER) -d postgres -tc "SELECT 1 FROM pg_database WHERE datname='$(AIRFLOW_DB_NAME)'" | tr -d '[:space:]'); \
	if [ "$$EXISTS" = "1" ]; then \
		echo "[airflow:init] Database already present"; \
	else \
		docker exec flumen_postgres psql -U $(POSTGRES_USER) -d postgres -c "CREATE DATABASE $(AIRFLOW_DB_NAME)" >/dev/null && \
		echo "[airflow:init] Database created"; \
	fi

.PHONY: health-airflow
health-airflow: ## Health check for Airflow webserver
	@echo "Checking Airflow health..."
	@if docker compose $(foreach f,$(COMPOSE_STACK),-f $f) ps -q $(AIRFLOW_CONTAINER) >/dev/null; then \
		docker compose $(foreach f,$(COMPOSE_STACK),-f $f) exec -T $(AIRFLOW_CONTAINER) curl -sf http://localhost:8080/health >/dev/null && \
		echo "✓ Airflow is reachable at http://localhost:$(AIRFLOW_PORT)" || \
		(echo "✗ Airflow did not respond" && exit 1); \
	else \
		echo "✗ Airflow container is not running"; \
		exit 1; \
	fi

# =============================================================================
# Utilities
# =============================================================================

.PHONY: logs-airflow
logs-airflow: ## Tail Airflow logs
	@docker compose $(foreach f,$(COMPOSE_STACK),-f $f) logs -f airflow

.PHONY: shell-airflow
shell-airflow: ## Open shell inside Airflow container
	docker compose $(foreach f,$(COMPOSE_STACK),-f $f) exec airflow bash

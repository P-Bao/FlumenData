# =============================================================================
# MLflow Makefile
# Experiment tracking server backed by PostgreSQL + MinIO
# =============================================================================

MLFLOW_PORT ?= 5000
MLFLOW_CONFIG_DIR := config/mlflow
MLFLOW_ENV_FILE := $(MLFLOW_CONFIG_DIR)/server.env
MLFLOW_CONTAINER := flumen_mlflow
MLFLOW_API_URL := http://localhost:$(MLFLOW_PORT)
MLFLOW_EXPERIMENT := flumen-default

# =============================================================================
# Configuration
# =============================================================================

.PHONY: config-mlflow
config-mlflow: $(MLFLOW_ENV_FILE) ## Generate MLflow environment configuration
	@echo "✓ MLflow configuration ready at $(MLFLOW_CONFIG_DIR)"

$(MLFLOW_ENV_FILE): templates/mlflow/server.env.tpl .env
	@echo "Generating MLflow server environment..."
	@mkdir -p $(MLFLOW_CONFIG_DIR)
	@envsubst < templates/mlflow/server.env.tpl > $(MLFLOW_ENV_FILE)
	@echo "✓ MLflow server environment rendered"

.PHONY: clean-mlflow-config
clean-mlflow-config: ## Remove generated MLflow configuration
	rm -f $(MLFLOW_ENV_FILE)
	@echo "✓ MLflow configuration cleaned"

# =============================================================================
# Initialization & Health
# =============================================================================

.PHONY: init-mlflow
init-mlflow: ## Create default experiment (idempotent)
	@echo "[mlflow:init] Ensuring $(MLFLOW_EXPERIMENT) experiment exists..."
	@RESP=$$(curl -s -X POST $(MLFLOW_API_URL)/api/2.0/mlflow/experiments/create \
		-H "Content-Type: application/json" \
		-d '{"name":"$(MLFLOW_EXPERIMENT)","artifact_location":"s3://$(MINIO_BUCKET)/$(MLFLOW_ARTIFACT_PATH)/experiments"}'); \
	if echo "$$RESP" | grep -q '"error_code"'; then \
		if echo "$$RESP" | grep -q 'RESOURCE_ALREADY_EXISTS'; then \
			echo "[mlflow:init] Experiment already exists"; \
		else \
			echo "$$RESP"; \
			exit 1; \
		fi; \
	else \
		echo "[mlflow:init] Experiment ready"; \
	fi
	@echo "[mlflow:init] ✓ MLflow experiment ready"

.PHONY: health-mlflow
health-mlflow:
	@echo "Checking MLflow health..."
	@if curl -sf $(MLFLOW_API_URL) >/dev/null; then \
		echo "✓ MLflow UI is reachable at $(MLFLOW_API_URL)"; \
	else \
		echo "✗ Unable to reach MLflow at $(MLFLOW_API_URL)"; \
		exit 1; \
	fi; \
	echo "✓ MLflow health check passed"

.PHONY: test-mlflow
test-mlflow: ## Smoke test MLflow API
	@echo "[mlflow:test] Listing experiments..."
	@(curl -sf $(MLFLOW_API_URL)/api/2.0/mlflow/experiments/list >/dev/null || \
		curl -sf -X POST -H "Content-Type: application/json" -d '{}' \
		$(MLFLOW_API_URL)/api/2.0/mlflow/experiments/list >/dev/null) && \
		echo "[mlflow:test] ✓ API reachable" || \
		(echo "[mlflow:test] ✗ API failed" && exit 1)

# =============================================================================
# Utilities
# =============================================================================

.PHONY: logs-mlflow
logs-mlflow: ## Tail MLflow logs
	@docker compose -f docker-compose.tier2.yml logs -f mlflow

.PHONY: shell-mlflow
shell-mlflow: ## Open shell inside MLflow container
	docker exec -it $(MLFLOW_CONTAINER) sh

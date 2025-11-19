# =============================================================================
# JupyterLab Makefile
# Interactive development environment with PySpark 4.0.1
# =============================================================================

# Configuration files
JUPYTERLAB_CONFIG_DIR := config/jupyterlab

# Docker image
JUPYTERLAB_IMAGE := flumendata/jupyterlab:spark-4.0.1

# =============================================================================
# Configuration Generation
# =============================================================================

.PHONY: config-jupyterlab
config-jupyterlab: $(JUPYTERLAB_CONFIG_DIR)/spark-defaults.conf ## Generate JupyterLab Spark configuration

$(JUPYTERLAB_CONFIG_DIR)/spark-defaults.conf: templates/jupyterlab/spark-defaults.conf.tpl .env
	@echo "Generating JupyterLab Spark configuration..."
	@mkdir -p $(JUPYTERLAB_CONFIG_DIR)
	@envsubst < templates/jupyterlab/spark-defaults.conf.tpl > $(JUPYTERLAB_CONFIG_DIR)/spark-defaults.conf
	@echo "✓ JupyterLab Spark configuration generated"

# =============================================================================
# Docker Image Management
# =============================================================================

.PHONY: build-jupyterlab
build-jupyterlab: ## Build JupyterLab Docker image
	@echo "Building JupyterLab image..."
	docker build -f docker/jupyterlab.Dockerfile -t $(JUPYTERLAB_IMAGE) .
	@echo "✓ JupyterLab image built: $(JUPYTERLAB_IMAGE)"

.PHONY: pull-jupyterlab
pull-jupyterlab: ## Pull JupyterLab image from registry
	docker pull $(JUPYTERLAB_IMAGE)

.PHONY: push-jupyterlab
push-jupyterlab: ## Push JupyterLab image to registry
	docker push $(JUPYTERLAB_IMAGE)

# =============================================================================
# Service Management
# =============================================================================

# up-tier2 is defined in main Makefile

.PHONY: down-tier2
down-tier2: ## Stop Tier 2 services
	docker compose -f docker-compose.tier2.yml down

.PHONY: restart-jupyterlab
restart-jupyterlab: ## Restart JupyterLab service
	docker compose -f docker-compose.tier2.yml restart jupyterlab

.PHONY: logs-jupyterlab
logs-jupyterlab: ## View JupyterLab logs
	docker compose -f docker-compose.tier2.yml logs -f jupyterlab

# =============================================================================
# Initialization
# =============================================================================

.PHONY: init-jupyterlab
init-jupyterlab: ## Create lakehouse databases from JupyterLab
	@echo "[jupyterlab:init] Creating lakehouse databases..."
	@echo "$(LAKEHOUSE_DATABASES)" | tr ',' '\n' | while read -r db; do \
		[ -z "$$db" ] && continue; \
		MSG="[jupyterlab:init]   Creating $$db (downloading dependencies this may take some time)"; \
		TMP_FILE="$$(mktemp)"; \
		( docker exec flumen_jupyterlab /usr/local/spark/bin/spark-sql \
			--master spark://spark-master:7077 \
			-e "CREATE DATABASE IF NOT EXISTS $$db LOCATION 's3a://$(MINIO_BUCKET)/warehouse/$$db.db'" \
			> "$$TMP_FILE" 2>&1 ) & \
		CMD_PID=$$!; \
		DOTS=""; \
		while kill -0 $$CMD_PID 2>/dev/null; do \
			DOTS="$$DOTS."; \
			if [ $${#DOTS} -ge 10 ]; then DOTS=""; fi; \
			printf "\r%s%s" "$$MSG" "$$DOTS"; \
			sleep 1; \
		done; \
		wait $$CMD_PID >/dev/null 2>&1; \
		STATUS=$$?; \
		printf "\r%s... done\033[K\n" "$$MSG"; \
		if [ $$STATUS -ne 0 ]; then \
			echo "[jupyterlab:init]   Failed to create $$db"; \
			cat "$$TMP_FILE"; \
			rm -f "$$TMP_FILE"; \
			exit $$STATUS; \
		fi; \
		rm -f "$$TMP_FILE"; \
	done
	@echo "[jupyterlab:init] ✓ Databases initialized"

# =============================================================================
# Access & Utilities
# =============================================================================

.PHONY: token-jupyterlab
token-jupyterlab: ## Get JupyterLab access token
	@docker exec flumen_jupyterlab jupyter server list 2>/dev/null | grep -oP "token=\K[a-f0-9]+" || \
		docker logs flumen_jupyterlab 2>&1 | grep -oP "token=\K[a-f0-9]+" | head -1

.PHONY: shell-jupyterlab
shell-jupyterlab: ## Open bash shell in JupyterLab container
	docker exec -it flumen_jupyterlab bash

.PHONY: python-jupyterlab
python-jupyterlab: ## Open Python shell in JupyterLab container
	docker exec -it flumen_jupyterlab python

# =============================================================================
# Health Checks
# =============================================================================

.PHONY: health-jupyterlab
health-jupyterlab: ## Check JupyterLab health
	@echo "Checking JupyterLab health..."
	@TIMEOUT=60; \
	STATUS="starting"; \
	while [ $$TIMEOUT -gt 0 ]; do \
		STATUS=$$(docker inspect --format '{{.State.Health.Status}}' flumen_jupyterlab 2>/dev/null); \
		if [ "$$STATUS" = "healthy" ]; then \
			break; \
		fi; \
		sleep 2; \
		TIMEOUT=$$((TIMEOUT - 2)); \
	done; \
	if [ "$$STATUS" = "healthy" ]; then \
		echo "✓ JupyterLab container is healthy (Docker healthcheck)"; \
	else \
		echo "✗ JupyterLab is not responding (status: $$STATUS)"; \
		docker inspect --format '{{json .State.Health}}' flumen_jupyterlab 2>/dev/null || true; \
		exit 1; \
	fi

# =============================================================================
# Testing
# =============================================================================

.PHONY: test-jupyterlab
test-jupyterlab: ## Test JupyterLab Spark integration
	@echo "Testing JupyterLab Spark integration..."
	@docker exec flumen_jupyterlab python -c "\
import sys; \
from pyspark.sql import SparkSession; \
spark = SparkSession.builder.appName('test').master('spark://spark-master:7077').getOrCreate(); \
print(f'Spark version: {spark.version}'); \
print(f'Catalog: {spark.conf.get(\"spark.sql.catalogImplementation\")}'); \
spark.sql('SHOW DATABASES').show(); \
spark.stop(); \
print('✓ JupyterLab Spark integration test passed')"

# =============================================================================
# Data Persistence Tests
# =============================================================================

.PHONY: persist-jupyterlab
persist-jupyterlab: ## Test JupyterLab notebook persistence
	@echo "Testing JupyterLab data persistence..."
	@# Create a test notebook
	@docker exec flumen_jupyterlab bash -c "echo 'test notebook content' > /home/jovyan/work/persist_test.txt"
	@# Restart container
	@docker compose -f docker-compose.tier2.yml restart jupyterlab > /dev/null 2>&1
	@sleep 10
	@# Verify file still exists
	@docker exec flumen_jupyterlab bash -c "test -f /home/jovyan/work/persist_test.txt" && \
		echo "✓ JupyterLab persistence verified" || \
		(echo "✗ JupyterLab persistence failed" && exit 1)
	@# Cleanup
	@docker exec flumen_jupyterlab rm -f /home/jovyan/work/persist_test.txt

# =============================================================================
# Cleanup
# =============================================================================

.PHONY: cleanup-jupyterlab
cleanup-jupyterlab: ## Cleanup JupyterLab test data
	@echo "Cleaning up JupyterLab test data..."
	@docker exec flumen_jupyterlab bash -c "rm -f /home/jovyan/work/persist_test.txt" 2>/dev/null || true
	@docker exec flumen_jupyterlab bash -c "rm -f /home/jovyan/work/test_*.ipynb" 2>/dev/null || true
	@echo "✓ JupyterLab test data cleaned"

.PHONY: clean-jupyterlab-config
clean-jupyterlab-config: ## Remove generated JupyterLab configuration
	rm -f $(JUPYTERLAB_CONFIG_DIR)/spark-defaults.conf
	@echo "✓ JupyterLab configuration cleaned"

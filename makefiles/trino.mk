# =============================================================================
# Trino Makefile
# Interactive SQL engine for Tier 3
# =============================================================================

TRINO_CONFIG_DIR := config/trino
TRINO_TEMPLATE_DIR := templates/trino
TRINO_CATALOG_DIR := $(TRINO_CONFIG_DIR)/catalog
TRINO_CONTAINER := flumen_trino
TRINO_PORT ?= 8082

# =============================================================================
# Configuration
# =============================================================================

.PHONY: config-trino
config-trino: $(TRINO_CONFIG_DIR)/config.properties \
	$(TRINO_CONFIG_DIR)/node.properties \
	$(TRINO_CONFIG_DIR)/jvm.config \
	$(TRINO_CATALOG_DIR)/hive.properties ## Generate Trino configuration
	@echo "✓ Trino configuration ready at $(TRINO_CONFIG_DIR)"

$(TRINO_CONFIG_DIR)/config.properties: $(TRINO_TEMPLATE_DIR)/config.properties.tpl .env
	@echo "Rendering Trino config.properties..."
	@mkdir -p $(TRINO_CONFIG_DIR)
	@envsubst < $< > $@

$(TRINO_CONFIG_DIR)/node.properties: $(TRINO_TEMPLATE_DIR)/node.properties.tpl .env
	@echo "Rendering Trino node.properties..."
	@mkdir -p $(TRINO_CONFIG_DIR)
	@envsubst < $< > $@

$(TRINO_CONFIG_DIR)/jvm.config: $(TRINO_TEMPLATE_DIR)/jvm.config.tpl
	@echo "Rendering Trino jvm.config..."
	@mkdir -p $(TRINO_CONFIG_DIR)
	@cp $< $@

$(TRINO_CATALOG_DIR)/hive.properties: $(TRINO_TEMPLATE_DIR)/catalog/hive.properties.tpl .env
	@echo "Rendering Trino Hive catalog..."
	@mkdir -p $(TRINO_CATALOG_DIR)
	@envsubst < $< > $@

.PHONY: clean-trino-config
clean-trino-config: ## Remove generated Trino configuration
	@rm -rf $(TRINO_CONFIG_DIR)
	@echo "✓ Trino configuration cleaned"

# =============================================================================
# Initialization & Health
# =============================================================================

.PHONY: init-trino
init-trino: ## Run Trino smoke checks
	@echo "[trino:init] Verifying catalogs..."
	@docker exec $(TRINO_CONTAINER) trino --server http://localhost:8080 --execute "SHOW CATALOGS" >/dev/null && \
		echo "[trino:init] ✓ Catalogs available" || \
		(echo "[trino:init] ✗ Failed to list catalogs" && exit 1)
	@echo "[trino:init] Checking Hive schema access..."
	@docker exec $(TRINO_CONTAINER) trino --server http://localhost:8080 --execute "SHOW SCHEMAS FROM hive" >/dev/null && \
		echo "[trino:init] ✓ Hive connector ready" || \
		(echo "[trino:init] ✗ Hive connector unavailable" && exit 1)

.PHONY: health-trino
health-trino: ## Health check for Trino coordinator
	@echo "Checking Trino health..."
	@curl -sf http://localhost:$(TRINO_PORT)/v1/info >/dev/null && \
		echo "✓ Trino is healthy" || \
		(echo "✗ Trino is not responding" && exit 1)

.PHONY: test-trino
test-trino: ## Run sample Trino query
	@echo "[trino:test] Listing catalogs..."
	@docker exec $(TRINO_CONTAINER) trino --server http://localhost:8080 --execute "SHOW CATALOGS" >/dev/null && \
		echo "[trino:test] ✓ Query executed" || \
		(echo "[trino:test] ✗ Query failed" && exit 1)

# =============================================================================
# Utilities
# =============================================================================

.PHONY: shell-trino
shell-trino: ## Open shell inside Trino container
	docker exec -it $(TRINO_CONTAINER) sh

.PHONY: sql-trino
sql-trino: ## Open Trino CLI shell
	docker exec -it $(TRINO_CONTAINER) trino --server http://localhost:8080

.PHONY: logs-trino
logs-trino: ## Tail Trino logs
	@docker compose -f docker-compose.tier3.yml logs -f trino

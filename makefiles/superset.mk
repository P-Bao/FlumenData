# =============================================================================
# Superset Makefile
# Business intelligence UI backed by PostgreSQL + Trino
# =============================================================================

SUPERSET_CONFIG_DIR := config/superset
SUPERSET_ENV_FILE := $(SUPERSET_CONFIG_DIR)/superset.env
SUPERSET_APP_CONFIG := $(SUPERSET_CONFIG_DIR)/superset_config.py
SUPERSET_CONTAINER := superset
COMPOSE_STACK := docker-compose.tier0.yml docker-compose.tier1.yml docker-compose.tier2.yml docker-compose.tier3.yml
SUPERSET_IMAGE := flumendata/superset:$(SUPERSET_VERSION)

# =============================================================================
# Configuration
# =============================================================================

.PHONY: config-superset
config-superset: $(SUPERSET_ENV_FILE) $(SUPERSET_APP_CONFIG) ## Generate Superset configuration
	@echo "✓ Superset configuration ready at $(SUPERSET_CONFIG_DIR)"

$(SUPERSET_ENV_FILE): templates/superset/superset.env.tpl .env
	@echo "Rendering Superset environment..."
	@mkdir -p $(SUPERSET_CONFIG_DIR)
	@envsubst < $< > $@

$(SUPERSET_APP_CONFIG): templates/superset/superset_config.py.tpl
	@echo "Rendering Superset app config..."
	@mkdir -p $(SUPERSET_CONFIG_DIR)
	@cp $< $@

.PHONY: clean-superset-config
clean-superset-config: ## Remove generated Superset configuration
	@rm -rf $(SUPERSET_CONFIG_DIR)
	@echo "✓ Superset configuration cleaned"

# =============================================================================
# Image Management
# =============================================================================

.PHONY: build-superset
build-superset: ## Build Superset image with required drivers
	@echo "Building Superset image ($(SUPERSET_IMAGE))..."
	docker build \
		-f docker/superset.Dockerfile \
		--build-arg SUPERSET_VERSION=$(SUPERSET_VERSION) \
		-t $(SUPERSET_IMAGE) .
	@echo "✓ Superset image built: $(SUPERSET_IMAGE)"

.PHONY: push-superset
push-superset: ## Push Superset image to registry
	docker push $(SUPERSET_IMAGE)

.PHONY: pull-superset
pull-superset: ## Pull Superset image from registry
	docker pull $(SUPERSET_IMAGE)

# =============================================================================
# Initialization & Health
# =============================================================================

.PHONY: superset-db
superset-db: ## Ensure Superset metadata database exists in PostgreSQL
	@echo "[superset:init] Ensuring database $(SUPERSET_DB_NAME) exists..."
	@EXISTS=$$(docker exec flumen_postgres psql -U $(POSTGRES_USER) -d postgres -tc "SELECT 1 FROM pg_database WHERE datname='$(SUPERSET_DB_NAME)'" | tr -d '[:space:]'); \
	if [ "$$EXISTS" = "1" ]; then \
		echo "[superset:init] Database already present"; \
	else \
		docker exec flumen_postgres psql -U $(POSTGRES_USER) -d postgres -c "CREATE DATABASE $(SUPERSET_DB_NAME)" >/dev/null && \
		echo "[superset:init] Database created"; \
	fi

.PHONY: health-superset
health-superset: ## Health check for Superset UI
	@echo "Checking Superset health..."
	@if docker compose $(foreach f,$(COMPOSE_STACK),-f $f) ps -q $(SUPERSET_CONTAINER) >/dev/null; then \
		docker compose $(foreach f,$(COMPOSE_STACK),-f $f) exec -T $(SUPERSET_CONTAINER) curl -sf http://localhost:8088/health >/dev/null && \
		echo "✓ Superset is reachable at http://localhost:$(SUPERSET_PORT)"; \
	else \
		echo "✗ Superset container is not running"; \
		exit 1; \
	fi

# =============================================================================
# Utilities
# =============================================================================

.PHONY: logs-superset
logs-superset: ## Tail Superset logs
	@docker compose $(foreach f,$(COMPOSE_STACK),-f $f) logs -f superset

.PHONY: shell-superset
shell-superset: ## Open shell inside Superset container
	docker compose $(foreach f,$(COMPOSE_STACK),-f $f) exec $(SUPERSET_CONTAINER) bash

# =============================================================================
# dbt Makefile
# Analytics engineering workflows against PostgreSQL
# =============================================================================

DBT_CONFIG_DIR := config/dbt
DBT_PROFILE := $(DBT_CONFIG_DIR)/profiles.yml
DBT_PROJECT_DIR := $(DBT_CONFIG_DIR)/project
DBT_TEMPLATE_DIR := templates/dbt/project
DBT_CONTAINER := flumen_dbt
DBT_CMD := docker exec $(DBT_CONTAINER) dbt
DBT_FLAGS := --project-dir /usr/app --profiles-dir /root/.dbt

# =============================================================================
# Configuration Generation
# =============================================================================

.PHONY: config-dbt
config-dbt: $(DBT_PROFILE) $(DBT_PROJECT_DIR)/dbt_project.yml ## Generate dbt profile and starter project
	@echo "✓ dbt configuration ready at $(DBT_CONFIG_DIR)"

$(DBT_PROFILE): templates/dbt/profiles.yml.tpl .env
	@echo "Generating dbt profile..."
	@mkdir -p $(DBT_CONFIG_DIR)
	@envsubst < templates/dbt/profiles.yml.tpl > $(DBT_PROFILE)
	@echo "✓ dbt profile rendered to $(DBT_PROFILE)"

$(DBT_PROJECT_DIR)/dbt_project.yml: $(DBT_TEMPLATE_DIR)/dbt_project.yml
	@if [ -f $@ ]; then \
		echo "dbt project already exists at $(DBT_PROJECT_DIR) (skipping template copy)"; \
	else \
		echo "Bootstrapping dbt project from templates..."; \
		mkdir -p $(DBT_PROJECT_DIR); \
		cp -R $(DBT_TEMPLATE_DIR)/* $(DBT_PROJECT_DIR); \
		echo "✓ dbt starter project copied to $(DBT_PROJECT_DIR)"; \
	fi

.PHONY: clean-dbt-config
clean-dbt-config: ## Remove generated dbt configuration
	@rm -rf $(DBT_CONFIG_DIR)
	@echo "✓ dbt configuration removed"

# =============================================================================
# Initialization & Health
# =============================================================================

.PHONY: init-dbt
init-dbt: ## Install dependencies and run the sample dbt project
	@echo "[dbt:init] Installing packages (if any)..."
	@$(DBT_CMD) deps $(DBT_FLAGS) >/dev/null
	@echo "[dbt:init] Running sample models..."
	@$(DBT_CMD) run $(DBT_FLAGS) >/dev/null
	@echo "[dbt:init] Executing tests..."
	@$(DBT_CMD) test $(DBT_FLAGS) >/dev/null
	@echo "[dbt:init] ✓ dbt project initialized"

.PHONY: health-dbt
health-dbt: ## Validate dbt connection to PostgreSQL
	@echo "Checking dbt connectivity..."
	@$(DBT_CMD) debug $(DBT_FLAGS) --target dev >/dev/null && \
		echo "✓ dbt is healthy" || \
		(echo "✗ dbt health check failed" && exit 1)

# =============================================================================
# dbt CLI helpers
# =============================================================================

.PHONY: shell-dbt
shell-dbt: ## Open bash shell inside the dbt container
	docker exec -it $(DBT_CONTAINER) bash

.PHONY: debug-dbt
debug-dbt: ## Run dbt debug
	@$(DBT_CMD) debug $(DBT_FLAGS)

.PHONY: run-dbt
run-dbt: ## Run dbt models
	@$(DBT_CMD) run $(DBT_FLAGS)

.PHONY: test-dbt
test-dbt: ## Run dbt tests
	@$(DBT_CMD) test $(DBT_FLAGS)

.PHONY: build-dbt
build-dbt: ## Run dbt build (deps + run + test)
	@$(DBT_CMD) build $(DBT_FLAGS)

.PHONY: seed-dbt
seed-dbt: ## Load dbt seeds
	@$(DBT_CMD) seed $(DBT_FLAGS)

.PHONY: deps-dbt
deps-dbt: ## Install dbt packages
	@$(DBT_CMD) deps $(DBT_FLAGS)

.PHONY: ls-dbt
ls-dbt: ## List dbt resources
	@$(DBT_CMD) ls $(DBT_FLAGS)

.PHONY: logs-dbt
logs-dbt: ## Tail dbt container logs
	@docker compose -f docker-compose.tier2.yml logs -f dbt

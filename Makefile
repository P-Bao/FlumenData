SHELL := /bin/sh
.DEFAULT_GOAL := init

# Load .env (export only variable names)
ifneq (,$(wildcard .env))
include .env
export $(shell sed -n 's/^\([A-Za-z_][A-Za-z0-9_]*\)=.*/\1/p' .env)
endif

# Services list
SERVICES := postgres valkey minio

include make/core.mk
include make/postgres.mk
include make/valkey.mk
include make/minio.mk

.PHONY: init prepare config up down restart logs ps health \
        selftest check clean clean-force reset reset-force \
		cleanup backup-postgres restore-postgres backup-valkey \
		restore-valkey backup-minio restore-minio backup-all \
		inspect-volumes fix-permissions

init: prepare config up
	@$(MAKE) health

prepare:
	@mkdir -p storage config
	@for s in $(SERVICES); do mkdir -p storage/$s config/$s; done
	@mkdir -p config/postgres
	@echo "[prepare] folders ready (postgres uses Docker volume)."

# Fix permissions for storage folders (not needed for postgres - uses Docker volume)
fix-permissions:
	@echo "[permissions] fixing storage permissions..."
	@docker run --rm -v "$(CURDIR)/storage/valkey:/data" alpine:3.20 sh -c "chmod -R 755 /data" 2>/dev/null || true
	@docker run --rm -v "$(CURDIR)/storage/minio:/data" alpine:3.20 sh -c "chmod -R 755 /data" 2>/dev/null || true
	@echo "[permissions] done (postgres uses managed volume)."

config:
	@for s in $(SERVICES); do $(MAKE) config-$$s; done
	@echo "[config] all service configs generated."

up:
	@$(DC) up -d
	@$(DC) ps

down:
	@$(DC) down -v || true

restart:
	@$(DC) restart

logs:
	@$(DC) logs -f $(S)

ps:
	@$(DC) ps

health:
	@$(MAKE) health-postgres
	@$(MAKE) health-valkey
	@$(MAKE) health-minio
	@echo "[health] all services healthy."

# ── Utilities ────────────────────────────────────────────────────────────────

check:
	@command -v docker >/dev/null 2>&1 || { echo "docker not found"; exit 1; }
	@docker version >/dev/null || { echo "docker daemon not running?"; exit 1; }
	@echo "[check] ok"

# Clean with confirmation
clean:
	@echo "⚠️  This will remove ALL generated configs."
	@read -p "Are you sure? [y/N] " ans; \
	if [ "$ans" = "y" ] || [ "$ans" = "Y" ]; then \
		$(MAKE) clean-force; \
	else echo "Aborted."; fi

# Clean configs only (volumes are preserved)
clean-force:
	@echo "[clean] removing config/..."
	@docker run --rm -v "$(CURDIR)/config:/t"  alpine:3.20 sh -c "rm -rf /t/*" || true
	@echo "[clean] done (Docker volumes preserved)."

reset:
	@echo "⚠️  FULL RESET: all data, configs and containers will be removed."
	@read -p "Proceed with full reset? [y/N] " ans; \
	if [ "$ans" = "y" ] || [ "$ans" = "Y" ]; then \
		echo "[reset] stopping containers..."; \
		$(DC) down -v || true; \
		echo "[reset] cleaning config..."; \
		$(MAKE) clean-force; \
		cd $(CURDIR); \
		$(MAKE) prepare; \
		$(MAKE) config; \
		$(MAKE) up; \
		$(MAKE) health; \
		echo "[reset] complete."; \
	else echo "Aborted."; fi

reset-force:
	@echo "[reset] performing full reset without confirmation..."
	@$(DC) down -v || true
	@$(MAKE) clean-force
	@cd $(CURDIR)
	@$(MAKE) prepare
	@$(MAKE) config
	@$(MAKE) up
	@$(MAKE) health
	@echo "[reset] complete."

cleanup:
	@echo "[cleanup] removing test data from all services..."
	@$(MAKE) cleanup-postgres
	@$(MAKE) cleanup-valkey
	@$(MAKE) cleanup-minio
	@echo "[cleanup] test data removed."

# Test suite
selftest: test-postgres test-valkey test-minio cleanup
	@echo "[selftest] tier 0 ok"

# ── Backup & Restore ─────────────────────────────────────────────────────────

# PostgreSQL backup/restore
backup-postgres:
	@echo "[backup] backing up postgres volume to ./backups/postgres-$(shell date +%Y%m%d-%H%M%S).tar.gz"
	@mkdir -p backups
	@docker run --rm -v flumendata_postgres_data:/data -v $(CURDIR)/backups:/backup alpine:3.20 \
		tar czf /backup/postgres-$(shell date +%Y%m%d-%H%M%S).tar.gz -C /data .
	@echo "[backup] done"

restore-postgres:
	@if [ -z "$(FILE)" ]; then echo "Usage: make restore-postgres FILE=backups/postgres-YYYYMMDD-HHMMSS.tar.gz"; exit 1; fi
	@echo "[restore] stopping postgres..."
	@$(DC) stop postgres
	@echo "[restore] restoring from $(FILE)..."
	@docker run --rm -v flumendata_postgres_data:/data -v $(CURDIR)/backups:/backup alpine:3.20 \
		sh -c "rm -rf /data/* && tar xzf /backup/$(notdir $(FILE)) -C /data"
	@echo "[restore] starting postgres..."
	@$(DC) start postgres
	@$(MAKE) health-postgres
	@echo "[restore] done"

# Valkey backup/restore
backup-valkey:
	@echo "[backup] backing up valkey volume to ./backups/valkey-$(shell date +%Y%m%d-%H%M%S).tar.gz"
	@mkdir -p backups
	@docker run --rm -v flumendata_valkey_data:/data -v $(CURDIR)/backups:/backup alpine:3.20 \
		tar czf /backup/valkey-$(shell date +%Y%m%d-%H%M%S).tar.gz -C /data .
	@echo "[backup] done"

restore-valkey:
	@if [ -z "$(FILE)" ]; then echo "Usage: make restore-valkey FILE=backups/valkey-YYYYMMDD-HHMMSS.tar.gz"; exit 1; fi
	@echo "[restore] stopping valkey..."
	@$(DC) stop valkey
	@echo "[restore] restoring from $(FILE)..."
	@docker run --rm -v flumendata_valkey_data:/data -v $(CURDIR)/backups:/backup alpine:3.20 \
		sh -c "rm -rf /data/* && tar xzf /backup/$(notdir $(FILE)) -C /data"
	@echo "[restore] starting valkey..."
	@$(DC) start valkey
	@$(MAKE) health-valkey
	@echo "[restore] done"

# MinIO backup/restore
backup-minio:
	@echo "[backup] backing up minio volume to ./backups/minio-$(shell date +%Y%m%d-%H%M%S).tar.gz"
	@mkdir -p backups
	@docker run --rm -v flumendata_minio_data:/data -v $(CURDIR)/backups:/backup alpine:3.20 \
		tar czf /backup/minio-$(shell date +%Y%m%d-%H%M%S).tar.gz -C /data .
	@echo "[backup] done"

restore-minio:
	@if [ -z "$(FILE)" ]; then echo "Usage: make restore-minio FILE=backups/minio-YYYYMMDD-HHMMSS.tar.gz"; exit 1; fi
	@echo "[restore] stopping minio..."
	@$(DC) stop minio
	@echo "[restore] restoring from $(FILE)..."
	@docker run --rm -v flumendata_minio_data:/data -v $(CURDIR)/backups:/backup alpine:3.20 \
		sh -c "rm -rf /data/* && tar xzf /backup/$(notdir $(FILE)) -C /data"
	@echo "[restore] starting minio..."
	@$(DC) start minio
	@$(MAKE) health-minio
	@echo "[restore] done"

# Backup all services at once
backup-all:
	@echo "[backup] backing up all services..."
	@$(MAKE) backup-postgres
	@$(MAKE) backup-valkey
	@$(MAKE) backup-minio
	@echo "[backup] all services backed up to ./backups/"
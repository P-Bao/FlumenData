# core.mk - common helpers and docker compose wrapper

# Compose wrapper
DC := docker compose

# Detect local envsubst
HAS_ENVSUBST := $(shell command -v envsubst >/dev/null 2>&1 && echo yes || echo no)

# Fallback: envsubst via Docker Alpine (WSL/Windows safe)
define docker_envsubst
	docker run --rm -i --env-file .env \
		-v "$(CURDIR)":/work -w /work \
		alpine:3.20 sh -c "apk add -q --no-progress gettext >/dev/null 2>&1; envsubst"
endef

# Template → Config generator
# Usage: $(call render_template,input.tpl,output.file)
define render_template
	@mkdir -p "$$(dirname $(2))"
	@if [ "$(HAS_ENVSUBST)" = "yes" ]; then \
		cat $(1) | envsubst > $(2); \
	else \
		cat $(1) | $(call docker_envsubst) > $(2); \
	fi; \
	echo "[template] $(1) -> $(2)"
endef

# Wait for container health=healthy (robust on WSL)
# Usage: $(call wait_for_healthy,container_name,timeout_seconds)
define wait_for_healthy
	@i=0; \
	while true; do \
		st=$$(docker inspect --format='{{.State.Health.Status}}' $(1) 2>/dev/null || echo starting); \
		if [ "$$st" = "healthy" ]; then echo "[wait] $(1) healthy"; break; fi; \
		i=$$((i+1)); if [ $$i -ge $(2) ]; then echo "[wait] timeout: $(1) status=$$st"; exit 1; fi; \
		sleep 1; \
	done
endef

# Initialize data directories for bind mounts
# Usage: make init-data-dirs
.PHONY: init-data-dirs
init-data-dirs:
	@echo "[init] Creating data directories at $(DATA_DIR)..."
	@mkdir -p "$(DATA_DIR)/minio/lakehouse"
	@mkdir -p "$(DATA_DIR)/minio/storage"
	@mkdir -p "$(DATA_DIR)/notebooks/_examples"
	@echo "[init] ✓ Data directories created"
	@echo "[init] "
	@echo "[init] Data location: $(DATA_DIR)"
	@echo "[init] - MinIO (lakehouse data): $(DATA_DIR)/minio/"
	@echo "[init] - Notebooks (your work):  $(DATA_DIR)/notebooks/"
	@echo "[init] "
	@echo "[init] 💡 Tip: You can version control your notebooks:"
	@echo "[init]    cd $(DATA_DIR)/notebooks && git init"
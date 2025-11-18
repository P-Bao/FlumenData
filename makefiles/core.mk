# core.mk - common helpers and docker compose wrapper

# Compose wrapper
DC := docker compose

# Platform detection
UNAME_S := $(shell uname -s 2>/dev/null || echo unknown)

# Resolve DATA_DIR to absolute path (handles relative paths like ../data-projects)
DATA_DIR_ABS := $(shell cd $(CURDIR) && realpath -m $(DATA_DIR) 2>/dev/null || echo $(DATA_DIR))

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

# Directory creation helper
define create_data_dir
	@echo "[init] Platform: $(UNAME_S)"
	@echo "[init] Data directory: $(DATA_DIR) -> $(DATA_DIR_ABS)"
	@if [ ! -d "$(DATA_DIR_ABS)" ]; then \
		echo "[init] Creating base directory: $(DATA_DIR_ABS)"; \
		mkdir -p "$(DATA_DIR_ABS)" 2>&1 || { \
			echo "[init] "; \
			echo "[init] ✗ Cannot create directory. Please run:"; \
			echo "[init]   mkdir -p $(DATA_DIR_ABS)"; \
			exit 1; \
		}; \
	fi
endef

# Initialize data directories for bind mounts
# Works on Linux, macOS, and WSL
.PHONY: init-data-dirs
init-data-dirs:
	@echo "[init] Initializing data directories"
	@if [ -f "$(DATA_DIR)" ]; then \
		echo "[init] ✗ ERROR: $(DATA_DIR) exists as a file, not a directory!"; \
		exit 1; \
	fi
	$(call create_data_dir)
	@echo "[init] ✓ Base directory ready: $(DATA_DIR)"
	@echo "[init] Creating subdirectories..."
	@mkdir -p "$(DATA_DIR)/minio/lakehouse" || { echo "[init] ✗ Failed to create minio/lakehouse"; exit 1; }
	@mkdir -p "$(DATA_DIR)/minio/storage" || { echo "[init] ✗ Failed to create minio/storage"; exit 1; }
	@mkdir -p "$(DATA_DIR)/notebooks/_examples" || { echo "[init] ✗ Failed to create notebooks"; exit 1; }
	@echo "[init] ✓ Data directories created successfully"
	@echo "[init] "
	@echo "[init] Data location:"
	@echo "[init]   Configured: $(DATA_DIR)"
	@echo "[init]   Resolved:   $(DATA_DIR_ABS)"
	@echo "[init] "
	@echo "[init] Structure:"
	@echo "[init]   ├── minio/lakehouse     (Delta Lake tables)"
	@echo "[init]   ├── minio/storage       (staging files)"
	@echo "[init]   └── notebooks/          (your work - can git init here!)"
	@echo "[init] "
	@echo "[init] 💡 Version control notebooks: cd $(DATA_DIR)/notebooks && git init"
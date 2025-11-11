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
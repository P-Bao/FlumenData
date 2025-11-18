# minio.mk - MinIO service targets

MINIO_TEMPLATES := templates/minio/policy-readonly.json.tpl
MINIO_OUTPUTS   := $(patsubst templates/minio/%.tpl,config/minio/%,$(MINIO_TEMPLATES))

config-minio: $(MINIO_OUTPUTS)
	@echo "[minio] config generated."

config/minio/%: templates/minio/%.tpl
	@mkdir -p $(dir $@)
	$(call render_template,$<,$@)

health-minio:
	@$(call wait_for_healthy,flumen_minio,180)

# MinIO client (mc) inside compose network
define mc
	docker run --rm --network $(COMPOSE_PROJECT_NAME)_default -i \
		-e MC_HOST_flumen=http://$$MINIO_ROOT_USER:$$MINIO_ROOT_PASSWORD@minio:9000 \
		minio/mc:RELEASE.2025-08-13T08-35-41Z $(1)
endef

.PHONY: test-minio persist-minio config-minio health-minio init-minio cleanup-minio

# Initialize MinIO: create lakehouse bucket
init-minio:
	@echo "[minio:init] creating buckets: $$MINIO_BUCKET (lakehouse) and $$MINIO_STORAGE_BUCKET (staging)..."
	@$(call mc, alias set flumen http://minio:9000 $$MINIO_ROOT_USER $$MINIO_ROOT_PASSWORD)
	@$(call mc, mb flumen/$$MINIO_BUCKET --ignore-existing || true)
	@$(call mc, mb flumen/$$MINIO_STORAGE_BUCKET --ignore-existing || true)
	@echo "[minio:init] buckets ready"

test-minio:
	@echo "[minio:test] creating bucket, uploading, listing..."
	@$(call mc, alias set flumen http://minio:9000 $$MINIO_ROOT_USER $$MINIO_ROOT_PASSWORD)
	@$(call mc, mb flumen/selftest --ignore-existing || true)
	@echo "hello-from-flumendata" > /tmp/minio-test.txt
	@docker run --rm --network $(COMPOSE_PROJECT_NAME)_default \
		-v /tmp/minio-test.txt:/tmp/test.txt \
		-e MC_HOST_flumen=http://$$MINIO_ROOT_USER:$$MINIO_ROOT_PASSWORD@minio:9000 \
		minio/mc:RELEASE.2025-08-13T08-35-41Z cp /tmp/test.txt flumen/selftest/hello.txt
	@rm -f /tmp/minio-test.txt
	@$(call mc, ls flumen/selftest)
	@$(call mc, cat flumen/selftest/hello.txt) | grep -q "hello-from-flumendata"
	@echo "[minio:test] test successful"

persist-minio:
	@echo "[minio:persist] restarting container to verify data..."
	@$(DC) restart minio
	@$(MAKE) health-minio
	@$(call mc, alias set flumen http://minio:9000 $$MINIO_ROOT_USER $$MINIO_ROOT_PASSWORD)
	@$(call mc, stat flumen/selftest/hello.txt) >/dev/null
	@echo "[minio:persist] ok"

cleanup-minio:
	@$(call mc, rb flumen/selftest --force)
	@echo "[minio:cleanup] bucket selftest removed."

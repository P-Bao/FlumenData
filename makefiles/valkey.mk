# valkey.mk - Valkey service targets

VALKEY_TEMPLATES := templates/valkey/valkey.conf.tpl
VALKEY_OUTPUTS   := $(patsubst templates/valkey/%.tpl,config/valkey/%,$(VALKEY_TEMPLATES))

config-valkey: $(VALKEY_OUTPUTS)
	@echo "[valkey] config generated."

config/valkey/%: templates/valkey/%.tpl
	@mkdir -p $(dir $@)
	$(call render_template,$<,$@)

health-valkey:
	@$(call wait_for_healthy,flumen_valkey,120)

.PHONY: test-valkey persist-valkey config-valkey health-valkey cleanup-valkey

test-valkey:
	@echo "[valkey:test] SET/GET..."
	@$(DC) exec -T valkey valkey-cli -h 127.0.0.1 -p $$VALKEY_PORT SET selftest:key "hello"
	@$(DC) exec -T valkey valkey-cli -h 127.0.0.1 -p $$VALKEY_PORT GET selftest:key | grep -q "hello"
	@echo "[valkey:test] ok"

persist-valkey:
	@echo "[valkey:persist] restarting container to verify data..."
	@$(DC) restart valkey
	@$(MAKE) health-valkey
	@$(DC) exec -T valkey valkey-cli -h 127.0.0.1 -p $$VALKEY_PORT GET selftest:key | grep -q "hello" || { echo "Key missing after restart (check AOF/dir)"; exit 1; }
	@echo "[valkey:persist] ok"

cleanup-valkey:
	@$(DC) exec -T valkey valkey-cli -h 127.0.0.1 -p $$VALKEY_PORT DEL selftest:key >/dev/null
	@echo "[valkey:cleanup] key selftest:key deleted."

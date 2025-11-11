# hive.mk - Hive Metastore targets

HIVE_TEMPLATES := templates/hive/hive-site.xml.tpl
HIVE_OUTPUTS   := $(patsubst templates/hive/%.tpl,config/hive/%,$(HIVE_TEMPLATES))

config-hive: $(HIVE_OUTPUTS)
	@echo "[hive] config generated."
	@mkdir -p config/spark
	@cp config/hive/hive-site.xml config/spark/hive-site.xml
	@echo "[hive] hive-site.xml copied to Spark config"

config/hive/%: templates/hive/%.tpl
	@mkdir -p $(dir $@)
	$(call render_template,$<,$@)

health-hive:
	@$(call wait_for_healthy,flumen_hive_metastore,180)

.PHONY: test-hive config-hive health-hive init-hive verify-hive

# Initialize Hive databases
init-hive:
	@echo "[hive:init] Metastore ready. Database creation handled via JupyterLab (see init-jupyterlab)."

# Verify Hive Metastore setup
verify-hive:
	@echo "$(BLUE)════════════════════════════════════════════════$(RESET)"
	@echo "$(BLUE)   Hive Metastore - Lakehouse Structure         $(RESET)"
	@echo "$(BLUE)════════════════════════════════════════════════$(RESET)"
	@echo ""
	@echo "$(YELLOW)📊 Databases:$(RESET)"
	@TMP_FILE="$$(mktemp)"; \
	( docker exec flumen_spark_master /opt/spark/bin/spark-sql \
		--master spark://spark-master:7077 \
		-e "SHOW DATABASES" > "$$TMP_FILE" 2>&1 ) & \
	CMD_PID=$$!; \
	MSG="[hive:verify] Downloading dependencies (This may take some time)"; \
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
		echo "[hive:verify]   Failed to load database list"; \
		cat "$$TMP_FILE"; \
		rm -f "$$TMP_FILE"; \
		exit $$STATUS; \
	fi; \
	DB_RAW="$$(cat "$$TMP_FILE")"; rm -f "$$TMP_FILE"; \
	echo "$$DB_RAW" | grep -v "INFO\|WARN\|Time taken" | tail -n +2 | while read -r db; do \
		[ -z "$$db" ] && continue; \
	done
	@echo ""
	@echo "$(YELLOW)🗄️  Metadata Database:$(RESET) PostgreSQL"
	@echo "$(YELLOW)💾 Storage Backend:$(RESET) s3a://$(MINIO_BUCKET)/warehouse"
	@echo "$(YELLOW)🔗 Metastore URI:$(RESET) thrift://hive-metastore:9083"
	@echo ""
	@echo "$(GREEN)════════════════════════════════════════════════$(RESET)"
	@echo "$(GREEN)✓ Verification complete$(RESET)"
	@echo "$(GREEN)════════════════════════════════════════════════$(RESET)"

# Test Hive Metastore
test-hive:
	@echo "[hive:test] checking metastore connectivity..."
	@docker exec flumen_spark_master /opt/spark/bin/spark-sql \
		--master spark://spark-master:7077 \
		-e "SHOW DATABASES" > /dev/null 2>&1
	@echo "[hive:test] ok"

# spark.mk - Spark cluster targets

SPARK_TEMPLATES := templates/spark/spark-env.sh.tpl templates/spark/spark-defaults.conf.tpl templates/spark/core-site.xml.tpl
SPARK_OUTPUTS   := $(patsubst templates/spark/%.tpl,config/spark/%,$(SPARK_TEMPLATES))

config-spark: $(SPARK_OUTPUTS)
	@echo "[spark] config generated."

config/spark/%: templates/spark/%.tpl
	@mkdir -p $(dir $@)
	$(call render_template,$<,$@)

health-spark-master:
	@$(call wait_for_healthy,flumen_spark_master,180)

health-spark-workers:
	@$(call wait_for_healthy,flumen_spark_worker1,180)
	@$(call wait_for_healthy,flumen_spark_worker2,180)

.PHONY: test-spark persist-spark config-spark health-spark-master health-spark-workers cleanup-spark

test-spark:
	@echo "[spark:test] running simple Pi job via spark-submit..."
	@$(DC) exec -T spark-master bash -lc "/opt/spark/bin/spark-submit --master spark://spark-master:7077 --class org.apache.spark.examples.SparkPi /opt/spark/examples/jars/spark-examples_2.13-*.jar 10"
	@echo "[spark:test] ok"

persist-spark:
	@echo "[spark:persist] restarting cluster to verify stability..."
	@$(DC) restart spark-worker1 spark-worker2 spark-master
	@$(MAKE) health-spark-master
	@$(MAKE) health-spark-workers
	@echo "[spark:persist] ok"

cleanup-spark:
	@echo "[spark:cleanup] no-op for now."

# Rendered to config/spark/spark-env.sh
# Minimal environment for Spark master/workers in standalone mode.
SPARK_MASTER_HOST=spark-master
SPARK_MASTER_PORT=7077
SPARK_MASTER_WEBUI_PORT=8080
SPARK_WORKER_CORES=${SPARK_WORKER_CORES}
SPARK_WORKER_MEMORY=${SPARK_WORKER_MEMORY}
SPARK_WORKER_WEBUI_PORT=8081

# Set user.home for Ivy cache when downloading Hive JARs
export SPARK_SUBMIT_OPTS="-Duser.home=/opt/spark"

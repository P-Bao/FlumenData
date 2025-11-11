# docker/spark.Dockerfile - Wrap apache/spark to add curl and prepare Ivy cache
FROM apache/spark:4.0.1
USER root
# Try apt -> microdnf -> apk
RUN (apt-get update && apt-get install -y curl procps) ||     (microdnf -y install curl procps && microdnf clean all) ||     (apk add --no-cache curl procps) || true
# Prepare writable ivy cache for spark user (uid 185)
RUN mkdir -p /opt/spark/.ivy2 && chown -R 185:0 /opt/spark/.ivy2
USER 185

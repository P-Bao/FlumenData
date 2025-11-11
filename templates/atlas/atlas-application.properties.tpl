# Rendered to config/atlas/atlas-application.properties
# Apache Atlas configuration for FlumenData

#########  Graph Database Configs  #########
atlas.graph.storage.backend=berkeleyje
atlas.graph.storage.directory=/opt/atlas/data/berkeley

#########  Notification Configs  #########
atlas.notification.embedded=true
atlas.kafka.data=/opt/atlas/data/kafka

#########  Entity Audit Configs  #########
atlas.audit.hbase.tablename=apache_atlas_entity_audit
atlas.audit.zookeeper.session.timeout.ms=1000
atlas.audit.hbase.zookeeper.quorum=localhost:2181

#########  High Availability Configuration ########
atlas.server.ha.enabled=false

######### Atlas Server Configs #########
atlas.rest.address=http://atlas:21000

######### Authentication Configuration #########
atlas.authentication.method.kerberos=false
atlas.authentication.method.file=true
atlas.authentication.method.file.filename=/opt/atlas/conf/users-credentials.properties

######### Authorization Configuration #########
atlas.authorizer.impl=simple
atlas.authorizer.simple.authz.policy.file=/opt/atlas/conf/atlas-simple-authz-policy.json

######### Atlas Notification Configuration #########
atlas.notification.create.topics=true
atlas.notification.replicas=1
atlas.notification.topics=ATLAS_HOOK,ATLAS_ENTITIES
atlas.notification.log.failed.messages=true
atlas.notification.consumer.retry.interval=500
atlas.notification.hook.retry.interval=1000

######### Hook Configuration #########
atlas.hook.hive.synchronous=false
atlas.hook.hive.numRetries=3
atlas.hook.hive.queueSize=10000

######### Hive Metastore Integration #########
atlas.cluster.name=flumendata
atlas.hook.hive.minThreads=1
atlas.hook.hive.maxThreads=5

######### LineageOnDemand Configuration #########
atlas.lineage.on.demand.enabled=true
atlas.lineage.on.demand.default.node.count=9

######### Type Cache Configuration #########
atlas.type.cache.impl=

######### Performance Configuration #########
atlas.graph.cache.db-cache=true
atlas.graph.cache.db-cache-clean-wait=20
atlas.graph.cache.db-cache-size=0.5
atlas.graph.cache.tx-cache-size=15000

######### Search Configuration #########
atlas.search.gremlin.enable=false

######### UI Configuration #########
atlas.ui.default.version=v2

######### HDFS Path Configurations #########
atlas.server.run.setup.on.start=false

######### Entity Audit Repository #########
atlas.EntityAuditRepository.impl=org.apache.atlas.repository.audit.InMemoryEntityAuditRepository

######### PostgreSQL Backend (Optional - for metadata) #########
# If we want to use PostgreSQL instead of BerkeleyDB in future
# atlas.graph.storage.backend=hbase2
# atlas.graph.storage.hbase.table=apache_atlas_janus

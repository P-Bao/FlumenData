# Apache Spark

O Apache Spark serve como o motor de computação distribuída para o FlumenData, fornecendo processamento de consultas e capacidades analíticas para o lakehouse.

## Visão Geral

**Imagem**: `flumendata/spark:4.0.1-health` (construída customizada)
**Base**: `apache/spark:4.0.1`
**Cluster**: 1 Master + 2 Workers
**Porta Master**: 7077 (protocolo Spark), 8080 (UI Web)
**Porta Worker**: 8081 (UI Web)
**Saúde**: Verificação HTTP na UI do Master

## Arquitetura

O cluster Spark fornece:
- **Computação distribuída**: 1 Master coordenando 2 nós Worker
- **Delta Lake 4.0**: Formato de tabela ACID com viagem no tempo
- **Catálogo Hive Metastore**: Namespace de 2 níveis (database.table)
- **Integração S3A**: Acesso direto ao armazenamento de objetos MinIO
- **Cache Ivy**: Resolução rápida de dependências para bibliotecas

## Dockerfile Customizado

Nossa imagem customizada adiciona utilitários de verificação de saúde e prepara o cache Ivy:

```dockerfile
FROM apache/spark:4.0.1
USER root

# Instalar curl e procps para verificações de saúde
RUN (apt-get update && apt-get install -y curl procps) || \
    (microdnf -y install curl procps && microdnf clean all) || \
    (apk add --no-cache curl procps) || true

# Preparar cache ivy gravável para o usuário spark (uid 185)
RUN mkdir -p /opt/spark/.ivy2 && chown -R 185:0 /opt/spark/.ivy2

USER 185
```

## Configuração

### spark-defaults.conf

Configuração gerada de `templates/spark/spark-defaults.conf.tpl`:

```properties
# Dependências JAR
spark.jars.packages io.delta:delta-spark_2.13:4.0.0,\
                   org.postgresql:postgresql:42.7.1,\
                   org.apache.hadoop:hadoop-aws:3.3.6,\
                   com.amazonaws:aws-java-sdk-bundle:1.12.367

# Extensões Delta Lake
spark.sql.extensions io.delta.sql.DeltaSparkSessionExtension
spark.sql.catalog.spark_catalog org.apache.spark.sql.delta.catalog.DeltaCatalog

# Integração Hive Metastore
spark.hadoop.hive.metastore.uris thrift://hive-metastore:9083
spark.sql.catalogImplementation hive
spark.sql.warehouse.dir s3a://lakehouse/warehouse

# Configuração MinIO S3A
spark.hadoop.fs.s3a.endpoint http://minio:9000
spark.hadoop.fs.s3a.path.style.access true
spark.hadoop.fs.s3a.connection.ssl.enabled false

# Otimização de Performance
spark.sql.adaptive.enabled true
spark.sql.adaptive.coalescePartitions.enabled true
```

### spark-env.sh

Variáveis de ambiente geradas de `templates/spark/spark-env.sh.tpl`:

```bash
SPARK_MASTER_HOST=spark-master
SPARK_MASTER_PORT=7077
SPARK_MASTER_WEBUI_PORT=8080
SPARK_WORKER_CORES=2
SPARK_WORKER_MEMORY=2g
SPARK_WORKER_WEBUI_PORT=8081
```

## Comandos Python CLI

```bash
# Configuração
python3 flumen config --service spark          # Gerar spark-defaults.conf e spark-env.sh

# Gerenciamento de serviço
python3 flumen up --tier 1              # Iniciar cluster Spark (Master + Workers)
python3 flumen logs --service spark-master            # Ver logs do Spark

# Saúde e verificação
python3 flumen health --service spark-master   # Verificar se o Master está saudável
python3 flumen health --service spark-worker1  # Verificar se os Workers estão saudáveis

# Testes
python3 flumen test --service spark-master            # Executar job de exemplo SparkPi
python3 flumen test --service spark-master --persistence         # Testar estabilidade de restart do cluster
```

## Arquitetura do Cluster

### Nó Master

O nó Master (`flumen_spark_master`):
- Coordena a execução de jobs através dos workers
- Fornece UI Web na porta 8080
- Aceita aplicações Spark na porta 7077
- Depende que o Hive Metastore esteja saudável

### Nós Worker

Dois nós worker (`flumen_spark_worker1`, `flumen_spark_worker2`):
- Executam tarefas atribuídas pelo Master
- 2 núcleos de CPU por worker
- 2GB de memória por worker
- Cada um fornece UI Web na porta 8081
- Iniciam apenas após o Master estar saudável

## Volumes Nomeados

O Spark usa quatro volumes nomeados para persistência:

```
flumen_spark_conf   # Arquivos de configuração do Spark
flumen_spark_ivy    # Cache Ivy para dependências JAR
flumen_spark_work   # Diretórios de trabalho dos workers
flumen_spark_logs   # Logs do Spark
```

## Shells Interativos

### Spark Shell (Scala)

```bash
python3 flumen shell-spark
# ou diretamente
docker exec -it flumen_spark_master /opt/spark/bin/spark-shell \
  --master spark://spark-master:7077
```

Exemplo de uso:
```scala
// Ler tabela Delta
val df = spark.read.format("delta").load("s3a://lakehouse/warehouse/my_table")
df.show()

// Escrever tabela Delta
df.write.format("delta").mode("overwrite")
  .save("s3a://lakehouse/warehouse/output_table")
```

### PySpark (Python)

```bash
python3 flumen shell-pyspark
# ou diretamente
docker exec -it flumen_spark_master /opt/spark/bin/pyspark \
  --master spark://spark-master:7077
```

Exemplo de uso:
```python
# Mostrar bancos de dados disponíveis
spark.sql("SHOW DATABASES").show()

# Criar um novo banco de dados
spark.sql("CREATE DATABASE IF NOT EXISTS analytics")

# Usar o banco de dados
spark.sql("USE analytics")

# Criar uma tabela Delta
spark.sql("""
    CREATE TABLE customers (
        id INT,
        name STRING,
        email STRING,
        country STRING,
        created_at TIMESTAMP
    ) USING DELTA
""")

# Inserir dados
spark.sql("""
    INSERT INTO customers VALUES
    (1, 'Alice', 'alice@example.com', 'USA', current_timestamp()),
    (2, 'Bob', 'bob@example.com', 'Canada', current_timestamp())
""")

# Consultar dados
spark.sql("SELECT * FROM customers").show()

# Ver histórico da tabela (time travel do Delta Lake)
spark.sql("DESCRIBE HISTORY customers").show(truncate=False)

# Consultar versão anterior
spark.sql("SELECT * FROM customers VERSION AS OF 0").show()
```

### Spark SQL

```bash
python3 flumen shell-spark-sql
# ou diretamente
docker exec -it flumen_spark_master /opt/spark/bin/spark-sql \
  --master spark://spark-master:7077
```

Exemplo de uso:
```sql
-- Listar databases
SHOW DATABASES;

-- Criar database
CREATE DATABASE IF NOT EXISTS analytics
LOCATION 's3a://lakehouse/warehouse/analytics.db';

-- Criar tabela Delta
CREATE TABLE analytics.sales (
  id BIGINT,
  amount DECIMAL(10,2),
  date DATE
) USING DELTA
LOCATION 's3a://lakehouse/warehouse/analytics.db/sales';

-- Consultar dados
SELECT date, SUM(amount) as total
FROM analytics.sales
GROUP BY date
ORDER BY date DESC;
```

## Recursos Delta Lake

### Transações ACID

Todas as operações de tabela são compatíveis com ACID:

```sql
-- Escritas atômicas
INSERT INTO my_table VALUES (1, 'data');

-- Atualizações e deleções
UPDATE my_table SET status = 'processed' WHERE id = 1;
DELETE FROM my_table WHERE date < '2024-01-01';

-- Merge (upsert)
MERGE INTO target_table t
USING source_table s ON t.id = s.id
WHEN MATCHED THEN UPDATE SET t.status = s.status
WHEN NOT MATCHED THEN INSERT *;
```

### Viagem no Tempo

Consultar versões históricas das tabelas:

```sql
-- Consultar em um timestamp
SELECT * FROM my_table TIMESTAMP AS OF '2024-11-10 10:00:00';

-- Consultar versão específica
SELECT * FROM my_table VERSION AS OF 42;

-- Ver histórico da tabela
DESCRIBE HISTORY my_table;
```

### Evolução de Schema

Delta Lake lida com mudanças de schema automaticamente:

```sql
-- Adicionar nova coluna
ALTER TABLE my_table ADD COLUMN new_field STRING;

-- Schema é mesclado durante escritas
INSERT INTO my_table SELECT *, 'default_value' as new_field FROM old_data;
```

## Submissão de Jobs

### Usando spark-submit

```bash
docker exec flumen_spark_master /opt/spark/bin/spark-submit \
  --master spark://spark-master:7077 \
  --deploy-mode client \
  --class com.example.MyApp \
  /path/to/my-app.jar
```

### Jobs Python

```bash
docker exec flumen_spark_master /opt/spark/bin/spark-submit \
  --master spark://spark-master:7077 \
  /path/to/my_script.py
```

## Cache Ivy

O Spark baixa automaticamente dependências no primeiro uso:

```bash
# Pacotes são cacheados em volume nomeado
docker exec flumen_spark_master ls -la /opt/spark/.ivy2/jars/
```

Pacotes comuns:
- `delta-spark_2.13-4.0.0.jar` - Núcleo Delta Lake
- `delta-storage-4.0.0.jar` - Camada de armazenamento Delta
- `postgresql-42.7.1.jar` - Driver JDBC PostgreSQL
- `hadoop-aws-3.3.6.jar` - Sistema de arquivos S3A
- `aws-java-sdk-bundle-1.12.367.jar` - AWS SDK

## Interfaces Web

Acesse as UIs do Spark após executar `python3 flumen up --tier 1`:

- **UI do Spark Master**: http://localhost:8080
  - Status do cluster e informações dos workers
  - Aplicações em execução e completadas
  - Alocação e utilização de recursos

- **UI do Spark Worker**: Não exposta (workers se comunicam internamente)

## Solução de Problemas

### Workers não conectando ao Master

Verificar conectividade de rede:
```bash
docker exec flumen_spark_worker1 nc -zv spark-master 7077
```

Verificar que o Master está saudável:
```bash
python3 flumen health --service spark-master
docker exec flumen_spark_master curl -sf http://localhost:8080/
```

### Problemas de download de dependências JAR

Verificar permissões do cache Ivy:
```bash
docker exec flumen_spark_master ls -la /opt/spark/.ivy2/
```

Limpar cache Ivy e reiniciar:
```bash
docker volume rm flumen_spark_ivy
python3 flumen restart
python3 flumen health --service spark-master
```

### Erros de conexão S3A

Verificar que o MinIO está acessível:
```bash
docker exec flumen_spark_master curl -I http://minio:9000
```

Verificar configuração S3A:
```bash
docker exec flumen_spark_master cat /opt/spark/conf/spark-defaults.conf | grep s3a
```

### Erros de conexão Hive Metastore

Verificar que o Hive Metastore está saudável:
```bash
python3 flumen health --service hive-metastore
docker exec flumen_spark_master nc -zv hive-metastore 9083
```

Verificar que hive-site.xml está presente:
```bash
docker exec flumen_spark_master ls -la /opt/spark/conf/hive-site.xml
```

## Localização de Armazenamento

Todos os dados do Spark são escritos no MinIO sob:
```
s3a://lakehouse/warehouse/
├── database1.db/
│   ├── table1/
│   │   ├── _delta_log/
│   │   └── part-00000-*.parquet
│   └── table2/
└── database2.db/
    └── table3/
```

Metadados Delta Lake são armazenados em diretórios `_delta_log/`:
```
table/_delta_log/
├── 00000000000000000000.json  # Transação inicial
├── 00000000000000000001.json  # Segunda transação
└── _last_checkpoint             # Ponteiro de checkpoint
```

## Dicas de Performance

### Particione seus dados

```sql
CREATE TABLE events (
  event_id BIGINT,
  event_time TIMESTAMP,
  user_id STRING
)
USING DELTA
PARTITIONED BY (DATE(event_time))
LOCATION 's3a://lakehouse/warehouse/events';
```

### Use Z-ordering

```sql
OPTIMIZE my_table ZORDER BY (user_id, date);
```

### Vacuum versões antigas

```sql
-- Remover arquivos mais antigos que 7 dias
VACUUM my_table RETAIN 168 HOURS;
```

### Analise tabelas

```sql
ANALYZE TABLE my_table COMPUTE STATISTICS;
```

## Compatibilidade

Spark 4.0.1 com Delta Lake 4.0 é compatível com:
- **Hive Metastore**: 2.x, 3.x, 4.x (usando protocolo Thrift)
- **Parquet**: Todas as versões
- **Delta Lake**: 2.x, 3.x, 4.x (compatível para frente)
- **Python**: 3.8+
- **Scala**: 2.13.x
- **Java**: 11, 17

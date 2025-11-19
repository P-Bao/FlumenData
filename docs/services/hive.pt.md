# Hive Metastore

O Apache Hive Metastore serve como a camada de catálogo para o FlumenData, fornecendo gerenciamento de metadados para o lakehouse.

## Visão Geral

**Imagem**: `flumendata/hive:standalone-metastore-4.1.0` (construída customizada)
**Base**: `apache/hive:standalone-metastore-4.1.0`
**Porta**: 9083 (Thrift)
**Saúde**: Verificação de processo (`pgrep -f HiveMetaStore`)

## Arquitetura

O Hive Metastore fornece:
- **Namespace de 2 níveis**: `database.table`
- **Backend PostgreSQL**: Metadados armazenados no PostgreSQL para durabilidade
- **API Thrift**: Interface padrão na porta 9083
- **Integração S3A**: Acesso direto ao armazenamento de objetos MinIO

## Dockerfile Customizado

Nossa imagem customizada adiciona os drivers JDBC necessários:

```dockerfile
FROM apache/hive:standalone-metastore-4.1.0
USER root

# Download dos drivers JDBC do PostgreSQL e bibliotecas AWS S3A
RUN curl -fsSL https://jdbc.postgresql.org/download/postgresql-42.7.1.jar \
    -o /opt/hive/lib/postgresql-jdbc.jar && \
    curl -fsSL https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.6/hadoop-aws-3.3.6.jar \
    -o /opt/hive/lib/hadoop-aws.jar && \
    curl -fsSL https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.367/aws-java-sdk-bundle-1.12.367.jar \
    -o /opt/hive/lib/aws-java-sdk-bundle.jar

USER hive
```

## Configuração

A configuração é gerada de `templates/hive/hive-site.xml.tpl`:

```xml
<configuration>
  <!-- Backend PostgreSQL -->
  <property>
    <name>javax.jdo.option.ConnectionURL</name>
    <value>jdbc:postgresql://postgres:5432/flumendata</value>
  </property>

  <!-- Integração MinIO S3A -->
  <property>
    <name>fs.s3a.endpoint</name>
    <value>http://minio:9000</value>
  </property>

  <!-- Localização do Warehouse -->
  <property>
    <name>hive.metastore.warehouse.dir</name>
    <value>s3a://lakehouse/warehouse</value>
  </property>
</configuration>
```

## Comandos Make

```bash
# Configuração
make config-hive           # Gerar hive-site.xml

# Gerenciamento de serviço
make up-tier1              # Iniciar Hive Metastore
make logs-hive             # Ver logs do Hive

# Saúde e verificação
make health-hive           # Verificar se o Hive está saudável
make verify-hive           # Verificar configuração do Hive e mostrar databases
make test-hive             # Testar conectividade do metastore
```

## Schema do Banco de Dados

O schema do metastore é automaticamente inicializado no PostgreSQL na primeira inicialização:

```bash
# Ver tabelas do Hive Metastore no PostgreSQL
docker exec flumen_postgres psql -U flumen -d flumendata -c "\dt"

# Verificar versão do Hive
docker exec flumen_postgres psql -U flumen -d flumendata -c 'SELECT * FROM "VERSION"'
```

Saída esperada:
```
VER_ID | SCHEMA_VERSION | VERSION_COMMENT
-------+----------------+----------------------------
     1 | 4.1.0          | Hive release version 4.1.0
```

## Criando Databases

Crie databases usando Spark SQL:

```bash
# Shell interativo Spark SQL
make shell-spark-sql

# Criar database
spark-sql> CREATE DATABASE my_database
           LOCATION 's3a://lakehouse/warehouse/my_database.db';

# Listar databases
spark-sql> SHOW DATABASES;
```

## Verificação

Execute o alvo de verificação para ver todos os databases:

```bash
make verify-hive
```

Isso exibe:
- Lista de todos os databases no metastore
- Backend do banco de metadados (PostgreSQL)
- Backend de armazenamento (URI S3A)
- URI Thrift do Metastore

## Solução de Problemas

### Metastore não inicia

Verificar logs para driver JDBC ausente:
```bash
make logs-hive | grep -i "jdbc\|driver\|postgres"
```

### Não pode conectar ao PostgreSQL

Verificar que o PostgreSQL está saudável e a conectividade de rede:
```bash
make health-postgres
docker exec flumen_hive_metastore nc -zv postgres 5432
```

### Tabelas não visíveis no Spark

Garantir que a configuração do Spark inclui hive-site.xml:
```bash
docker exec flumen_spark_master ls -l /opt/spark/conf/hive-site.xml
```

## Localização de Armazenamento

Todos os dados de tabelas são armazenados no MinIO sob:
```
s3a://lakehouse/warehouse/
├── database1.db/
│   ├── table1/
│   └── table2/
└── database2.db/
    └── table3/
```

## Compatibilidade

O Hive Metastore é compatível com:
- Apache Spark 2.x, 3.x, 4.x
- Presto / Trino
- Apache Impala
- AWS Athena (com sincronização do Glue Data Catalog)
- Qualquer ferramenta que suporte protocolo Thrift do Hive Metastore

# Variáveis de Ambiente

O FlumenData usa variáveis definidas no arquivo `.env` para configurar todos os serviços. Elas alimentam o Docker Compose e os templates do Makefile.

## Gestão de Configuração

### Sistema de Templates

Os arquivos de configuração são gerados a partir de templates:

```
templates/               # Templates-fonte
├── hive/
│   └── hive-site.xml.tpl
├── spark/
│   ├── spark-defaults.conf.tpl
│   └── spark-env.sh.tpl
├── jupyterlab/
│   └── spark-defaults.conf.tpl
├── minio/
│   └── policy-readonly.json.tpl
├── superset/
│   ├── superset.env.tpl
│   └── superset_config.py.tpl
└── trino/
    └── catalog/

config/                  # Arquivos gerados (NÃO EDITE)
├── hive/
│   └── hive-site.xml
├── spark/
│   ├── spark-defaults.conf
│   ├── spark-env.sh
│   └── hive-site.xml (cópia do hive/)
├── jupyterlab/
│   └── spark-defaults.conf
├── minio/
│   └── policy-readonly.json
├── superset/
│   ├── superset.env
│   └── superset_config.py
└── trino/
    └── catalog/
```

### Regenerando Configurações

Após alterar `.env`, gere tudo novamente:

```bash
# Gerar todos os arquivos
python3 flumen config

# Gerar serviços específicos
python3 flumen config --service hive
python3 flumen config --service spark
python3 flumen config --service minio
python3 flumen config --service jupyterlab
python3 flumen config --service trino
python3 flumen config --service superset

# Reiniciar para aplicar
python3 flumen restart
```

!!! warning "Nunca edite os arquivos gerados"
    Tudo em `config/` é sobrescrito. Sempre edite os templates dentro de `templates/` e execute `python3 flumen config`.

## Variáveis Principais

### PostgreSQL

```bash
# Configuração do PostgreSQL
POSTGRES_USER=flumen           # Usuário do banco
POSTGRES_PASSWORD=flumen123    # Senha
POSTGRES_DB=flumendata         # Nome do banco
POSTGRES_PORT=5432             # Porta exposta
```

**Usado por:**
- Contêiner PostgreSQL
- Hive Metastore (conexão JDBC)
- Comandos CLI que acessam o banco

**Exemplos:**
```bash
# Conectar ao PostgreSQL
docker exec -it flumen_postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB}

# Alterar senha (exige restart)
POSTGRES_PASSWORD=nova_senha_segura
python3 flumen config
python3 flumen restart
```

### MinIO

```bash
# Armazenamento S3 compatível
MINIO_ROOT_USER=minioadmin           # Usuário admin
MINIO_ROOT_PASSWORD=minioadmin123    # Senha (mínimo 8 chars)
MINIO_SERVER_URL=http://minio:9000   # Endpoint interno
MINIO_CONSOLE_PORT=9001              # Porta da UI
MINIO_BUCKET=lakehouse               # Bucket do warehouse Delta
MINIO_STORAGE_BUCKET=storage         # Bucket de staging
```

**Usado por:**
- Contêiner MinIO
- Spark (configuração S3A)
- Hive Metastore

**Notas de segurança:**
- Use senhas fortes em produção
- Credenciais padrão apenas para desenvolvimento
- Console: http://localhost:9001

**Exemplos:**
```bash
# Trocar credenciais
MINIO_ROOT_USER=admin
MINIO_ROOT_PASSWORD=SenhaMuitoForte123
python3 flumen config
python3 flumen restart

# Criar buckets adicionais
docker exec flumen_minio mc mb /data/bronze
```

### Hive Metastore

```bash
HIVE_METASTORE_URI=thrift://hive-metastore:9083
```

**Usado por:**
- Spark (catálogo)
- Ferramentas que consomem o metastore

**Exemplos:**
```bash
# Verificar conectividade
docker exec flumen_spark_master nc -zv hive-metastore 9083

# Inspecionar logs
python3 flumen logs --service hive-metastore
```

### Spark

```bash
SPARK_MASTER_HOST=spark-master    # Host do master
SPARK_MASTER_PORT=7077            # Porta protocolo Spark
SPARK_MASTER_WEBUI_PORT=8080      # Porta da UI
SPARK_WORKER_CORES=2              # Núcleos por worker
SPARK_WORKER_MEMORY=2g            # Memória por worker
```

**Usado por:**
- Master e workers do Spark
- Template `spark-env.sh`

**Exemplos:**
```bash
# Aumentar recursos
SPARK_WORKER_CORES=4
SPARK_WORKER_MEMORY=4g
python3 flumen config --service spark
python3 flumen restart

# Abrir UI
open http://localhost:8080
```

### Delta Lake e Dependências

```bash
DELTA_VERSION=4.0.0
SCALA_BINARY_VERSION=2.13
POSTGRESQL_JDBC_VERSION=42.7.1
HADOOP_AWS_VERSION=3.3.6
AWS_SDK_BUNDLE_VERSION=1.12.367
```

**Usado por:**
- `spark-defaults.conf`
- Cache Ivy do Spark

**Mudando versões:**
```bash
DELTA_VERSION=4.1.0
python3 flumen config --service spark

# Limpar cache Ivy para baixar novos JARs
docker volume rm flumen_spark_ivy
python3 flumen restart
```

!!! warning "Compatibilidade de versões"
    Garanta compatibilidade entre Delta Lake, Spark e Scala. Consulte a [documentação oficial](https://docs.delta.io/latest/releases.html).

### Trino

```bash
# Coordenador Trino
TRINO_PORT=8082             # Porta/UI exposta (mapeada para 8080 interno)
TRINO_VERSION=450           # Tag da imagem
TRINO_ENVIRONMENT=lakehouse # Valor gravado em node.properties
```

**Usado por:**
- `docker-compose.tier3.yml` (ports, imagem)
- `makefiles/trino.mk`
- `templates/trino/node.properties.tpl`

**Exemplos:**
```bash
# Evitar conflito de porta
TRINO_PORT=9090
python3 flumen up --tier 3

# Fixar outra versão
TRINO_VERSION=448
python3 flumen up --tier 3
```

### Superset

```bash
# UI de BI Superset
SUPERSET_VERSION=5.0.0            # Tag da imagem
SUPERSET_PORT=8088                # Porta exposta
SUPERSET_DB_NAME=superset         # Banco de metadados no PostgreSQL
SUPERSET_SECRET_KEY=flumen_superset_secret
SUPERSET_ADMIN_USERNAME=admin
SUPERSET_ADMIN_PASSWORD=admin123
SUPERSET_ADMIN_EMAIL=admin@flumen.local
SUPERSET_ADMIN_FIRST_NAME=Superset
SUPERSET_ADMIN_LAST_NAME=Admin
```

**Usado por:**
- Templates de Superset
- `makefiles/superset.mk` (config + bootstrap do banco)
- `docker-compose.tier3.yml`
- `docker/superset.Dockerfile`

**Exemplos:**
```bash
# Alterar porta da UI
SUPERSET_PORT=8090
python3 flumen up --tier 3

# Mudar a senha padrão antes de gerar configs
SUPERSET_ADMIN_PASSWORD=SenhaSuperForte
python3 flumen config --service superset
```

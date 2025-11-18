# Referência de Comandos Make

O FlumenData fornece uma coleção completa de comandos Make para operar o lakehouse.

## Referência Rápida

```bash
make init          # Inicialização completa
make health        # Checar saúde de todos os serviços
make ps            # Containers em execução
make summary       # Resumo do ambiente
make logs          # Ver logs
make restart       # Reiniciar todos os serviços
make reset         # Resetar e reinicializar
make clean         # Remover tudo (DESTRUTIVO)
```

## Comandos de Inicialização

### `make init`
Inicialização completa (recomendado para a primeira execução).

**O que faz:**
1. Gera arquivos de configuração
2. Constrói imagens customizadas
3. Sobe Tier 0 (PostgreSQL, MinIO)
4. Inicializa buckets do MinIO
5. Sobe Tier 1 (Hive + Spark)
6. Sobe Tier 2 (JupyterLab)
7. Sobe Tier 3 (Trino + Superset)
8. Executa health checks
9. Mostra resumo

```bash
make init
```

### `make config`
Renderiza todas as configurações.

```bash
make config                  # Todos os serviços
make config-postgres         # Serviço específico
make config-minio
make config-hive
make config-spark
make config-jupyterlab
make config-trino
make config-superset
```

Use depois de alterar `.env`, atualizar templates ou quando arquivos gerados sumirem.

## Gestão de Serviços

### Subir Serviços

```bash
make up            # Tiers 0–3
make up-tier0      # PostgreSQL + MinIO
make up-tier1      # Hive + Spark
make up-tier2      # JupyterLab
make up-tier3      # Trino + Superset
```

### Parar Serviços

```bash
make down          # Tudo
make down-tier0
make down-tier1
```

### Reiniciar

```bash
make restart       # down + up
```

## Health Checks

```bash
make health
make health-tier0
make health-tier1
make health-tier2
make health-tier3

make health-postgres
make health-minio
make health-hive
make health-spark-master
make health-spark-workers
make health-jupyterlab
make health-trino
make health-superset
```

## Comandos do Superset

```bash
make build-superset    # Construir imagem customizada
make logs-superset     # Seguir logs do container
make shell-superset    # Shell interativo (útil para CLI do superset)
```

## Testes

### `make test`
Executa todos os testes de integração.

**Valida:**
- PostgreSQL: conexão, criação de tabela, persistência
- MinIO: bucket, upload/download
- Hive Metastore: criação de database, metadados
- Spark: submissão de job + Delta Lake
- JupyterLab: health HTTP
- Trino: consulta via CLI

### Testes por Tier

```bash
make test-tier0
make test-tier1
make test-tier2
make test-tier3
```

### Serviços Individuais

```bash
make test-postgres
make test-minio
make test-hive
make test-spark
make test-jupyterlab
make test-trino
```

### Testes de Persistência

```bash
make persist-postgres
make persist-minio
make persist-spark
make persist-jupyterlab
```

## Verificação

### `make verify-hive`
Mostra bancos e configurações do Hive Metastore.

### `make summary`
Exibe versão, status dos serviços, portas, URLs, volumes e parâmetros principais.

## Logs

```bash
make logs           # Todos os serviços
make logs-tier0
make logs-tier1
make logs-tier2
make logs-tier3

make logs-postgres
make logs-minio
make logs-hive
make logs-spark
make logs-jupyterlab
make logs-trino
make logs-superset
```

Opções adicionais:
```bash
# Últimas 100 linhas
docker-compose -f docker-compose.tier0.yml logs --tail=100

# Última hora
docker-compose -f docker-compose.tier0.yml logs --since=1h
```

## Shells Interativos

### Bancos de Dados

#### `make shell-postgres`
Abre o `psql` interativo.

```bash
make shell-postgres
```

### Spark

```bash
make shell-spark      # Spark shell (Scala)
make shell-pyspark    # PySpark shell
make shell-spark-sql  # Spark SQL shell
```

Exemplos:
```scala
val df = spark.read.format("delta").table("quickstart.customers")
df.show()
```
```python
df = spark.read.format("delta").table("quickstart.customers")
df.show()
```

### Trino CLI

```bash
make sql-trino
# SHOW CATALOGS;
```

### MinIO Client

```bash
make mc
mc ls local/lakehouse/warehouse
```

## Manutenção

### `make reset`
Reinicialização completa preservando dados.

1. Para tudo
2. Mantém volumes
3. Executa `make init`

```bash
make reset
```

!!! tip "Dados preservados"
    Use para aplicar mudanças grandes de configuração.

### `make clean`
Remove tudo, incluindo volumes.

1. Para serviços
2. Remove containers
3. Remove volumes/redes
4. Limpa `config/`

```bash
make clean
```

!!! danger "Perda de dados"
    Exige confirmação (`Are you sure? [y/N]`). Use apenas se quiser começar do zero.

## Comandos Docker Úteis

```bash
make ps                # Status dos containers
make help              # Lista de alvos com descrição

docker system df       # Uso de disco
docker volume ls
```

Limpeza:
```bash
docker image prune
docker volume prune
docker system prune -a --volumes
```

## Build

```bash
make build             # Rebuild de todas as imagens customizadas
# ou
docker build -f docker/hive.Dockerfile -t flumendata/hive:standalone-metastore-4.1.0 .
```

## Dicas Rápidas

| Tarefa | Comando |
|--------|---------|
| Primeiro uso | `make init` |
| Checar ambiente | `make health` |
| Ver logs | `make logs` |
| Aplicar mudança no `.env` | `make config && make restart` |
| Testes | `make test` |
| Abrir Spark SQL | `make shell-spark-sql` |
| Resumo | `make summary` |
| Reset seguro | `make reset` |
| Deletar tudo | `make clean` |

## Uso Avançado

```bash
# Pipeline típico após mudar .env
make config && make restart && make health

# Reiniciar apenas se config funcionar
make config && make restart || echo "Config falhou"

# Depuração rápida
make logs | grep ERROR
docker inspect flumen_spark_master
docker exec flumen_spark_master /opt/spark/bin/spark-submit --version
```

## Próximos Passos

- [Variáveis de Ambiente](environment.md)
- [Arquitetura](../getting-started/architecture.md)
- [Guia de Testes](../development/testing.md)

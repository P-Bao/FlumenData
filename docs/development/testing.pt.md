# Guia de Testes

O FlumenData possui testes para garantir que todos os componentes funcionem em conjunto.

## Arquitetura de Testes

### Níveis

1. **Health Checks** – verifica se os serviços estão de pé
2. **Smoke Tests** – validações básicas de funcionalidade
3. **Testes de Integração** – fluxos multi-serviço
4. **Testes de Persistência** – confirmam se dados resistem a reinícios

### Organização

```
Hierarquia de Testes:
├── make test
│   ├── make test-tier0
│   │   ├── make test-postgres
│   │   └── make test-minio
│   └── make test-tier1
│       ├── make test-hive
│       └── make test-spark
│   └── make test-tier2
│       └── make test-jupyterlab
│   └── make test-tier3
│       └── make test-trino
```

## Executando Testes

### Suite Completa

```bash
make test
```

**Saída esperada:**
```
[test] Running all tests...
[postgres:test] ✓ Connection successful
...
[test] All tests passed!
```

### Tiers Específicos

```bash
make test-tier0
make test-tier1
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

## Detalhes dos Testes

### PostgreSQL (makefiles/postgres.mk)

Valida:
1. Conexão (`psql`)
2. Criação de tabela
3. Inserção de dados
4. Consulta aos dados

```makefile
test-postgres:
	@docker exec flumen_postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "SELECT 1"
	@...
```

### MinIO (makefiles/minio.mk)

Valida:
1. Conexão via `mc`
2. Criação/listagem de bucket
3. Upload/download de objeto
4. Limpeza

### Hive Metastore (makefiles/hive.mk)

Valida:
1. Conectividade Thrift via `spark-sql`
2. Criação de database no warehouse Delta
3. Persistência de metadados no PostgreSQL
4. Limpeza da estrutura criada

### Spark (makefiles/spark.mk)

Valida:
1. Submissão do job `SparkPi`
2. Execução via `spark-submit` no master
3. Logs retornando sucesso

### JupyterLab (makefiles/jupyterlab.mk)

Valida:
1. Criação de `SparkSession` via PySpark
2. Execução de `SHOW DATABASES`
3. Fechamento da sessão

### Trino (makefiles/trino.mk)

Valida:
1. Execução do CLI `trino`
2. `SHOW CATALOGS`
3. `SHOW SCHEMAS FROM hive`

## Testes de Persistência

Os alvos `make persist-*` reiniciam serviços e verificam se os dados permanecem.

Exemplo (PostgreSQL):
```bash
make persist-postgres
```
1. Reinicia o container
2. Executa `make health-postgres`
3. Conta linhas da tabela `selftest`

## Boas Práticas

- Execute `make test` antes de abrir PR
- Use `make test-tierX` durante o desenvolvimento de cada tier
- Adicione novos testes junto com novos serviços ou features
- Utilize os comandos `make logs-*` para debugging quando um teste falhar

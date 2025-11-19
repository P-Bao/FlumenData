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
├── python3 flumen test
│   ├── python3 flumen test --tier 0
│   │   ├── python3 flumen test --service postgres
│   │   └── python3 flumen test --service minio
│   └── python3 flumen test --tier 1
│       ├── python3 flumen test --service hive-metastore
│       └── python3 flumen test --service spark-master
│   └── python3 flumen test --tier 2
│       └── python3 flumen test --service jupyterlab
│   └── python3 flumen test --tier 3
│       └── python3 flumen test --service trino
```

## Executando Testes

### Suite Completa

```bash
python3 flumen test
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
python3 flumen test --tier 0
python3 flumen test --tier 1
```

### Serviços Individuais

```bash
python3 flumen test --service postgres
python3 flumen test --service minio
python3 flumen test --service hive-metastore
python3 flumen test --service spark-master
python3 flumen test --service jupyterlab
python3 flumen test --service trino
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

Os comandos de persistência reiniciam serviços e verificam se os dados permanecem.

Exemplo (PostgreSQL):
```bash
python3 flumen test --service postgres --persistence
```
1. Reinicia o container
2. Executa verificação de saúde do postgres
3. Conta linhas da tabela `selftest`

## Boas Práticas

- Execute `python3 flumen test` antes de abrir PR
- Use `python3 flumen test --tier <N>` durante o desenvolvimento de cada tier
- Adicione novos testes junto com novos serviços ou features
- Utilize os comandos `python3 flumen logs --service <serviço>` para debugging quando um teste falhar

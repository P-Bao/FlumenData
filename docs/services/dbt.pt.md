# dbt (Tier 2 – Análise & Desenvolvimento)

**Propósito:** Fluxos de analytics engineering (modelos/testes/docs) executados dentro da rede do FlumenData utilizando PostgreSQL e tabelas expostas via Spark.

## Imagem
- Imagem customizada construída a partir de `docker/dbt.Dockerfile`, instalando `dbt-core==${DBT_CORE_VERSION}` e os adapters do [`dbt-labs/dbt-adapters`](https://github.com/dbt-labs/dbt-adapters) definidos em `DBT_ADAPTERS` (padrão `dbt-postgres`).
- É possível incluir múltiplos adapters (ex.: `dbt-postgres` + `dbt-spark[PyHive]`) para reutilizar o mesmo container em diferentes engines.

## Configuração
- Variáveis de ambiente: `POSTGRES_*` e as variáveis específicas `DBT_TARGET_SCHEMA` e `DBT_THREADS` definidas em `.env`.
- Volumes montados:
  - `./config/dbt/profiles.yml` → `/root/.dbt/profiles.yml` (gerado via `envsubst`).
  - `./config/dbt/project` → `/usr/app` (workspace editável do projeto).
  - `flumen_shared_data` → `/data` (opcional para troca com o JupyterLab).
- Healthcheck: `dbt debug --project-dir /usr/app --profiles-dir /root/.dbt`.

!!! tip "Alternando adapters"
    Defina `DBT_ADAPTERS` no `.env` (ex.: `dbt-postgres==1.7.14 dbt-spark[PyHive]==1.7.2`) e rode `make up-tier2` novamente. A build do Docker reinstalará automaticamente os adapters solicitados.

## Como é gerado
- `make config-dbt` renderiza `templates/dbt/profiles.yml.tpl` e copia o projeto inicial de `templates/dbt/project/`.
- O projeto inicial inclui um modelo simples (`models/example.sql`) e testes de esquema para que `dbt run/test` funcionem imediatamente.

## Uso
```bash
make up-tier2          # também inicia o container do dbt
make shell-dbt         # abre um shell no container
make debug-dbt         # valida conectividade (dbt debug)
make run-dbt           # executa todos os modelos em /config/dbt/project
make test-dbt          # roda os testes de esquema/dados
make build-dbt         # deps + seed + run + test
```

## Fluxo rápido
1. Ajuste `.env` caso precise de outro schema ou número de threads.
2. Rode `make config-dbt` (já faz parte de `make config`) para garantir que o profile e o projeto existam.
3. Edite os modelos em `config/dbt/project/models/` no editor preferido ou via `make shell-dbt`.
4. Execute `make run-dbt` / `make test-dbt` para materializar objetos no PostgreSQL.
5. Use o JupyterLab ou o Spark para consultar os objetos gerados.

## Solução de problemas
- Falhas em `dbt debug` geralmente indicam PostgreSQL offline ou credenciais divergentes do `.env`.
- Para reiniciar o workspace, rode `make clean-dbt-config` e depois `make config-dbt` para recriar o projeto inicial.

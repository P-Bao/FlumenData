# PostgreSQL (Tier 0 – Fundação)

**Finalidade:** Banco relacional para metadados usados por orquestração, BI e serviços da plataforma.

## Imagem
- Docker image: `postgres:17.6-alpine3.22` (fixa, nunca `:latest`)

## Configuração
- Variáveis do `.env`: `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`, `POSTGRES_PORT`.
- Volume persistente: `postgres_data` → `/var/lib/postgresql/data`.
- Healthcheck: `pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}`.
- Arquivos estáticos: usando defaults do container (sem arquivo customizado em `/config/postgres` neste tier).

## Como é gerado
Config é criada via **Makefile**; não edite arquivos manualmente.
- Alvo: `make config-postgres` (sem alterações, usa defaults).

## Validação
```bash
# Aguardar saúde
make health-postgres

# Smoke test (criar tabela, inserir, selecionar)
make test-postgres

# Persistência (reiniciar e verificar linhas)
make persist-postgres
```

## Endpoints úteis
- Porta no host: `5432` (mapeada para `5432`).

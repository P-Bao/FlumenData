# Trino (Tier 3 – Orquestração & BI)

**Propósito:** Engine SQL interativo que expõe as tabelas do Hive/Delta Lake (armazenadas no MinIO) para ferramentas de BI e orquestração.

## Imagem
- Imagem oficial `trinodb/trino:${TRINO_VERSION}` com o conector Hive configurado para o metastore compartilhado.

## Configuração
- Templates em `templates/trino/` são renderizados para `config/trino/` via `python3 flumen config --service trino`.
- Variáveis de ambiente principais (`.env`):
  - `TRINO_PORT` – porta exposta no host (mapeada para a porta interna 8080).
  - `TRINO_VERSION` – tag da imagem do Trino.
  - `TRINO_ENVIRONMENT` – usado em `node.properties`.
  - `HIVE_METASTORE_URI`, `MINIO_ROOT_USER`, `MINIO_ROOT_PASSWORD`, `MINIO_SERVER_URL` – reutilizados no conector Hive.
- Arquivos gerados:
  - `config.properties`, `node.properties`, `jvm.config`.
  - `catalog/hive.properties` (pré-configurado para o Hive Metastore + MinIO).

## Uso
```bash
python3 flumen up --tier 3          # Sobe Trino + Superset (requer tiers 0–2 ativos)
python3 flumen shell-trino       # Abre um shell dentro do container
python3 flumen sql-trino         # Inicia o CLI conectado ao coordenador
```

A UI fica disponível em `http://localhost:${TRINO_PORT}` quando o container estiver healthy.

## Inicialização & Saúde
- Inicialização: A CLI executa `SHOW CATALOGS` e `SHOW SCHEMAS FROM hive` via CLI para garantir que o coordenador e o conector Hive estejam prontos.
- `python3 flumen health --service trino` faz um probe HTTP leve em `/v1/info`.
- O healthcheck do Docker replica o mesmo endpoint, então `docker compose ps` reflete o status real.

## Conectividade
- O catálogo Hive aponta para o mesmo metastore usado pelos jobs Spark do JupyterLab, logo schemas e tabelas Delta aparecem automaticamente.
- As credenciais S3 apontam para o MinIO (`s3://$(MINIO_BUCKET)/warehouse`), permitindo leitura/escrita via Trino.

## Troubleshooting
- **401/Forbidden:** verifique se o catálogo Hive recebeu as credenciais do MinIO (`config/trino/catalog/hive.properties`).
- **Catálogo ausente:** confirme que o Tier 1 (Hive Metastore) está saudável antes de subir o Tier 3.
- **Conflito de porta:** ajuste `TRINO_PORT` se `8082` já estiver em uso localmente e rode `python3 flumen config --service trino` antes de `python3 flumen up --tier 3`.

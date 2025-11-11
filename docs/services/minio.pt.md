# MinIO (Tier 0 – Fundação)

**Finalidade:** Armazenamento de objetos compatível com S3 para o Lake (bronze/silver/gold).

## Imagem
- Docker image: `minio/minio:RELEASE.2025-09-07T16-13-09Z` (fixa no `docker-compose.yml`).

## Configuração
- Variáveis do `.env`: `MINIO_ROOT_USER`, `MINIO_ROOT_PASSWORD`, `MINIO_SERVER_URL`, `MINIO_BROWSER_REDIRECT_URL`, `MINIO_PORT_API`, `MINIO_PORT_CONSOLE`.
- Volume persistente: `minio_data` → `/data`.
- Template de policy: `/templates/minio/policy-readonly.json.tpl` → `/config/minio/policy-readonly.json`.
- Healthcheck: `GET /minio/health/live` no container.
- MinIO Client (mc) fixo para testes e backups dentro da rede do Compose.

## Como é gerado
- Alvo: `make config-minio` renderiza templates em `/config/minio/` usando envsubst (local ou via Docker).

## Validação
```bash
# Aguardar saúde
make health-minio

# Smoke test: criar bucket, enviar e ler um arquivo
make test-minio

# Persistência: reiniciar e verificar objeto
make persist-minio
```

## Endpoints úteis
- API: `http://localhost:9000`
- Console/UI: `http://localhost:9001`

# MinIO (Tier 0 – Fundação)

**Finalidade:** Armazenamento de objetos compatível com S3 para o Lake (bronze/silver/gold).

## Imagem
- Docker image: `minio/minio:RELEASE.2025-09-07T16-13-09Z` (fixa no `docker-compose.yml`).

## Configuração
- Variáveis do `.env`: `MINIO_ROOT_USER`, `MINIO_ROOT_PASSWORD`, `MINIO_SERVER_URL`, `MINIO_BROWSER_REDIRECT_URL`, `MINIO_PORT_API`, `MINIO_PORT_CONSOLE`.
- Bind mount: `${DATA_DIR}/minio` → `/data` (contém os buckets `lakehouse` e `storage`).
- Template de policy: `/templates/minio/policy-readonly.json.tpl` → `/config/minio/policy-readonly.json`.
- Healthcheck: `GET /minio/health/live` no container.
- MinIO Client (mc) fixo para testes e backups dentro da rede do Compose.

### Buckets Padrão
- `MINIO_BUCKET` (padrão `lakehouse`): Warehouse Delta em `s3a://lakehouse/warehouse`.
- `MINIO_STORAGE_BUCKET` (padrão `storage`): Bucket de staging para CSV/XLSX/ZIP antes da ingestão.

## Como é gerado
- Comando: `python3 flumen config --service minio` renderiza templates em `/config/minio/` usando envsubst (local ou via Docker).

## Validação
```bash
# Aguardar saúde
python3 flumen health --service minio

# Smoke test: criar bucket, enviar e ler um arquivo
python3 flumen test --service minio

# Persistência: reiniciar e verificar objeto
python3 flumen test --service minio --persistence
```

## Endpoints úteis
- API: `http://localhost:9000`
- Console/UI: `http://localhost:9001`

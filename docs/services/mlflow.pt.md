# MLflow (Tier 2 – Análise & Desenvolvimento)

**Propósito:** Centralizar o rastreamento de experimentos (parâmetros, métricas e artefatos) gerados por notebooks, jobs Spark ou modelos dbt.

## Imagem
- Imagem customizada construída a partir de `docker/mlflow.Dockerfile`, instalando `mlflow==${MLFLOW_VERSION}` e as dependências para PostgreSQL/S3.

## Configuração
- Template: `templates/mlflow/server.env.tpl` → `config/mlflow/server.env` via `make config-mlflow`.
- Variáveis no `.env`:
  - `MLFLOW_PORT` – porta exposta para a UI (`5000` por padrão).
  - `MLFLOW_ARTIFACT_PATH` – prefixo no bucket MinIO (`s3://lakehouse/<path>`).
  - `MLFLOW_VERSION` – versão do MLflow instalada no container.
- Backend store: PostgreSQL (`postgresql+psycopg2://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:${POSTGRES_PORT}/${POSTGRES_DB}`).
- Artifact store: MinIO usando as credenciais S3 já definidas.
- Volume nomeado: `flumen_mlflow_data` montado em `/opt/mlflow`.

## Uso
```bash
make up-tier2          # Inicia o MLflow junto com JupyterLab e dbt
make health-mlflow     # Verifica a saúde do servidor
make logs-mlflow       # Acompanha os logs
make shell-mlflow      # Abre um shell no container
```

Acesse a interface em `http://localhost:${MLFLOW_PORT}`.

### Tracking URI
```python
import mlflow
mlflow.set_tracking_uri("http://mlflow:5000")      # dentro da rede Docker
# ou a partir do host:
mlflow.set_tracking_uri("http://127.0.0.1:5000")
```

### Artefatos e credenciais
Artefatos ficam em `s3://$(MINIO_BUCKET)/${MLFLOW_ARTIFACT_PATH}`. Reutilize as credenciais do MinIO já configuradas no `.env` (variáveis de ambiente ou `~/.aws/credentials` quando estiver fora dos containers).

## Inicialização
`make init-mlflow` cria (de forma idempotente) o experimento inicial `flumen-default`. Experimentos adicionais podem ser criados via UI ou API quando necessário.

## Solução de problemas
- **Conexão recusada / erro 500:** garanta que os serviços da Tier 0 (Postgres e MinIO) estejam saudáveis. O MLflow depende de ambos.
- **Falha ao enviar artefatos:** confirme que `MLFLOW_S3_ENDPOINT_URL` aponta para `http://minio:9000` e que o bucket existe (`make health-minio`).
- **Avisos de SSL com o MinIO:** em modo de desenvolvimento usamos HTTP. Em produção utilize TLS e ajuste `MLFLOW_S3_ENDPOINT_URL`.

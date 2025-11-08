# Valkey (Tier 0 – Fundação)

**Finalidade:** Armazenamento chave/valor em memória para cache e coordenação.

## Imagem
- Docker image: `valkey/valkey:9.0.0-alpine3.22` (fixa no `docker-compose.yml`).

## Configuração
- Ambiente: `VALKEY_PORT` do `.env`.
- Volume persistente: `valkey_data`.
- Template de config: `/templates/valkey/valkey.conf.tpl` → `/config/valkey/valkey.conf`.
- Healthcheck: container deve atingir `healthy` antes dos testes.

## Como é gerado
- Alvo: `make config-valkey` renderiza templates em `/config/valkey/` usando envsubst (local ou via Docker).

## Validação
```bash
# Aguardar saúde
make health-valkey

# Smoke test: SET/GET
make test-valkey

# Persistência: reiniciar e verificar chave
make persist-valkey
```

## Endpoints úteis
- Porta no host: `6379` (mapeada para `6379`).

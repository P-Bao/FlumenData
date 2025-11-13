# Superset (Tier 3 – Orquestração & BI)

**Objetivo:** Interface de exploração SQL e dashboards sobre os catálogos do Trino (Hive, Delta/Lakehouse).

## Imagem
- Imagem customizada construída a partir de `docker/superset.Dockerfile`, baseada em `apache/superset:${SUPERSET_VERSION}`.
  - Instala `psycopg2-binary` para o banco de metadados PostgreSQL.
  - Instala `sqlalchemy-trino` para conectar ao Trino sem dependências extras.

## Configuração
- Templates:
  - `templates/superset/superset.env.tpl` → `config/superset/superset.env` via `make config-superset`.
  - `templates/superset/superset_config.py.tpl` → `config/superset/superset_config.py`.
- Variáveis principais (definidas em `.env`):
  - `SUPERSET_VERSION` – tag da imagem.
  - `SUPERSET_PORT` – porta do host/UI (padrão `8088`).
  - `SUPERSET_DB_NAME` – banco de metadados criado no PostgreSQL.
  - `SUPERSET_SECRET_KEY` – chave secreta do Flask para sessões/CSRF.
  - `SUPERSET_ADMIN_*` – usuário admin inicial (usuário, senha, e-mail, nomes).
- Dependências em runtime:
  - **Banco de metadados**: PostgreSQL (`postgresql+psycopg2://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${SUPERSET_DB_NAME}`).
  - **Cache / assíncrono**: Valkey via `REDIS_URL=redis://valkey:${VALKEY_PORT}/0`.
  - **Volume nomeado**: `flumen_superset_home` montado em `/app/superset_home` (configurações, uploads, estado).

## Uso
```bash
make build-superset    # (Opcional) constrói a imagem customizada
make config-superset   # Renderiza env + config
make superset-db       # Garante o banco de metadados no PostgreSQL
make up-tier3          # Sobe Trino + Superset + Airflow
make health-superset   # Verifica saúde via HTTP
make logs-superset     # Segue os logs
make shell-superset    # Abre bash dentro do container
```

Acesse `http://localhost:${SUPERSET_PORT}` (padrão `http://localhost:8088`).

### Credenciais Padrão
- Usuário: `admin`
- Senha: `admin123`

Altere esses valores no `.env` antes de rodar `make config-superset` para não usar os padrões.

### Conectar o Superset ao Trino
Crie um novo **Database** no Superset:

1. Vá em **Settings → Database Connections → + Database**.
2. Escolha **Other** e use a URI SQLAlchemy (o driver `sqlalchemy-trino` já está instalado):
   - Dentro da rede Docker: `trino://trino@trino:8080/lakehouse`
   - A partir do host: `trino://trino@localhost:8082/lakehouse` (ou `host.docker.internal` no macOS/Windows se `localhost` não alcançar o container)
3. Teste a conexão e salve. Os catálogos (`hive`, `delta`, `lakehouse`) ficam disponíveis para criar datasets.

### Detalhes de Inicialização
O comando do container executa:

1. `superset db upgrade` – migrações.
2. `superset fab create-admin ...` – cria o usuário admin de forma idempotente.
3. `superset init` – carrega papéis e permissões.
4. Inicia o Gunicorn (`gunicorn -w 4 -k gevent ...`).

## Solução de Problemas
- **Falha imediata no login**: garanta que cookies estejam habilitados e que `SUPERSET_SECRET_KEY` permaneça estável entre reinicializações.
- **Superset inacessível**: execute `make health-superset` e verifique `docker compose -f docker-compose.tier3.yml logs superset`.
- **Erros no banco de metadados**: rode `make superset-db` depois que o PostgreSQL estiver saudável para criar o banco `superset` antes de iniciar o container.
- **Timeout consultando o Trino**: verifique se todos os tiers estão na mesma rede Docker (`make up`) e se a URI SQLAlchemy utiliza o hostname interno `trino`.

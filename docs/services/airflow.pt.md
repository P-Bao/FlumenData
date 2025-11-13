# Airflow (Tier 3 – Orquestração & BI)

**Objetivo:** Orquestrar e monitorar pipelines ETL/ELT que alimentam o lakehouse (Spark, Trino etc.).

## Imagem
- Imagem oficial `apache/airflow:${AIRFLOW_VERSION}` executando scheduler + webserver no mesmo contêiner (LocalExecutor).

## Configuração
- Template: `templates/airflow/airflow.env.tpl` → `config/airflow/airflow.env` via `make config-airflow`.
- Variáveis principais (definidas no `.env`):
  - `AIRFLOW_VERSION` – tag da imagem Docker.
  - `AIRFLOW_PORT` – porta do host/UI (padrão `8085`).
  - `AIRFLOW_DB_NAME` – nome do banco de metadados dentro do PostgreSQL.
  - `AIRFLOW_ADMIN_*` – credenciais do usuário admin inicial.
  - `AIRFLOW_FERNET_KEY` e `AIRFLOW_SECRET_KEY` – chaves usadas para criptografar conexões e sessões.
- Dependências em runtime:
  - **Banco de metadados**: PostgreSQL (Tier 0 compartilhado).
  - **Executor**: LocalExecutor (não precisa de Celery/Redis).
  - **Volumes nomeados**: `flumen_airflow_dags`, `flumen_airflow_logs`, `flumen_airflow_plugins` (DAGs permanecem em volume Docker por enquanto).

## Uso
```bash
make config-airflow    # Renderiza o arquivo de ambiente
make airflow-db        # Garante o banco de metadados no PostgreSQL
make up-tier3          # Sobe Trino + Superset + Airflow
make health-airflow    # Verifica o /health do webserver
make logs-airflow      # Segue os logs do Airflow
make shell-airflow     # Abre bash dentro do contêiner
```

Acesse `http://localhost:${AIRFLOW_PORT}` (padrão `http://localhost:8085`).

### Credenciais Padrão
- Usuário: `admin`
- Senha: `admin123`

Altere esses valores no `.env` antes de rodar `make config-airflow` para evitar o uso de padrões.

### DAGs e Persistência
- Os DAGs ficam em `/opt/airflow/dags`, persistidos via o volume `flumen_airflow_dags`. Em um passo futuro você pode trocar para um bind mount e editar DAGs diretamente no host.
- Logs e plugins seguem o mesmo padrão (`flumen_airflow_logs`, `flumen_airflow_plugins`).

### Detalhes de Inicialização
O comando do contêiner executa:
1. `airflow db migrate` – aplica migrações no PostgreSQL compartilhado.
2. `airflow users create ...` – cria o usuário admin de forma idempotente usando os valores do `.env`.
3. Inicia o scheduler em background e o webserver (Gunicorn) em foreground.

## Solução de Problemas
- **Erros no banco de metadados**: verifique se o PostgreSQL está saudável (Tier 0) e rode `make airflow-db` para criar o banco.
- **Webserver inacessível**: rode `make logs-airflow` e confira stack traces; também valide `http://localhost:${AIRFLOW_PORT}/health`.
- **DAGs não atualizam**: lembre-se de que os DAGs vivem no volume Docker. Edite-os via `make shell-airflow` em `/opt/airflow/dags` ou troque para um bind mount quando decidir gerenciá-los a partir do host.

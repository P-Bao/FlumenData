# FlumenData

This [README](./README.md) is available in English 

FlumenData é um ambiente **Lakehouse open-source** projetado para replicar uma plataforma de dados moderna completa utilizando apenas tecnologias de código aberto.  
Ele oferece uma stack **modular, totalmente containerizada e reprodutível** — cobrindo desde armazenamento e governança até orquestração e observabilidade — que pode ser iniciada com um único comando.

## 🚀 Objetivo

Oferecer um ambiente de nível de produção, totalmente reprodutível, para equipes de engenharia e análise de dados experimentarem, testarem e aprenderem conceitos modernos de plataformas de dados.

## 🧩 Visão da Arquitetura

O FlumenData é estruturado em camadas independentes de serviços:
- **Tier 0 – Fundação:** PostgreSQL, Valkey, MinIO  
- **Tier 1 – Dados e Governança:** Spark, Unity Catalog  
- **Tier 2 – Desenvolvimento e ML:** JupyterLab, dbt, MLflow  
- **Tier 3 – Orquestração e BI:** Airflow, Trino, Superset  
- **Tier 4 – Observabilidade e Acesso:** Prometheus, Grafana, NGINX

Cada serviço inclui healthchecks, volumes persistentes e arquivos de configuração estáticos no diretório `/config/`.

## ⚙️ Iniciando o Ambiente

```bash
# Inicializar o ambiente
make init
```

Este comando executa automaticamente:
- Criação das pastas e volumes necessários.
- Geração de todos os arquivos de configuração em /config/.
- Inicialização completa da stack via Docker Compose.

## 📁 Estrutura do Projeto

```bash
FlumenData/
├── config/         # Arquivos de configuração estáticos
├── docker/         # Dockerfiles e scripts de entrada
├── docs/           # Documentação MkDocs (EN + PT)
├── storage/        # Armazenamento persistente
├── workspace/      # Notebooks, jobs ETL/ELT
└── docker-compose.yml
```

## 📖 Documentação
Toda a documentação é mantida em inglês e português dentro do diretório /docs/.

---
🧠 FlumenData — Lakehouse moderno, aberto e reprodutível para todos.

---

## ✅ Validação do Tier 0 (PostgreSQL, Valkey, MinIO)

Após `make init`, valide cada serviço com:

```bash
# PostgreSQL
make health-postgres && make test-postgres && make persist-postgres

# Valkey
make config-valkey && make health-valkey && make test-valkey && make persist-valkey

# MinIO
make config-minio && make health-minio && make test-minio && make persist-minio
```

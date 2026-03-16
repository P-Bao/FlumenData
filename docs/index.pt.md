# FlumenData

<div class="fd-hero">
  <img src="/assets/images/flumendata-logowithname.png" alt="FlumenData logo">
  <p>Lakehouse componível baseado em Docker Compose, unindo Spark 4, Delta Lake 4, Trino, Superset e MinIO.</p>
  <div class="fd-tags">
    <span class="fd-tag trino">Trino SQL</span>
    <span class="fd-tag jupiter">JupyterLab</span>
    <span class="fd-tag superset">Superset BI</span>
    <span class="fd-tag healthy">Tiers saudáveis</span>
  </div>
</div>

!!! tip "Status do Projeto"
    **Tier 0 está validado**: PostgreSQL e MinIO possuem healthchecks, volumes nomeados e configurações em `/config`.
    **Tier 1 está operacional**: Apache Spark 4.0.1, Hive Metastore 4.1.0 e Delta Lake 4.0 estão implantados e testados.
    **Tier 2 e Tier 3 estão ativos**: JupyterLab, Trino e Superset prontos para demonstrações.

## Início Rápido

```bash
# 1) Clone o repositório
git clone https://github.com/lucianomauda/FlumenData.git
cd FlumenData

# 2) Inicialize o ambiente completo
python3 flumen init

# 3) Verifique que todos os serviços estão saudáveis
python3 flumen health

# 4) Visualize o resumo do ambiente
python3 flumen summary
```

## Arquitetura

FlumenData implementa uma arquitetura lakehouse moderna com:

```mermaid
    subgraph Dashboard
        COLLECTOR[Coletor de Métricas]
    end
    subgraph API
        API_SVC[API de Upload de Dados]
    end
    subgraph Tier0
        MINIO[MinIO S3]
        POSTGRES[PostgreSQL]
    end
    subgraph Tier1
        SPARK[Spark 4.0.1]
        HIVE[Hive Metastore]
        DELTA[Tabelas Delta Lake]
    end
    subgraph Tier2
        JUPYTER[JupyterLab]
    end
    subgraph Tier3
        TRINO[Trino]
        SUPERSET[Superset]
    end

    API_SVC --> MINIO
    COLLECTOR --> SPARK
    COLLECTOR --> POSTGRES
    MINIO --> DELTA
    POSTGRES --> HIVE
    HIVE --> SPARK
    SPARK --> DELTA
    TRINO --> HIVE
    TRINO --> MINIO
    SUPERSET --> TRINO
    JUPYTER --> SPARK
```

### Stack Tecnológico

**Camada de Armazenamento:**
- **MinIO** - Armazenamento de objetos compatível com S3 para o data lake
- **Delta Lake 4.0** - Formato de tabela ACID com capacidades de viagem no tempo

**Camada de Metadados:**
- **Hive Metastore 4.1.0** - Catálogo padrão da indústria (namespace de 2 níveis: database.table)
- **PostgreSQL** - Backend para metadados do Hive Metastore

**Camada de Computação:**
- **Apache Spark 4.0.1** - Motor de processamento e consultas distribuído (Master + 2 Workers)

**Camada de Analytics:**
- **JupyterLab** - IDE PySpark acessível via navegador

**Camada de SQL & BI:**
- **Trino** - Gateway SQL distribuído sobre o lakehouse
- **Apache Superset** - Dashboards, gráficos e SQL Lab

**Camada de Dashboard & API:**
- **Coletor de Métricas** - monitoramento automatizado e coleta de métricas
- **API de Upload de Dados** - Ponto de ingestão seguro para dados brutos

## Estrutura do Projeto

```
/FlumenData/
├── config/             # Configurações renderizadas (auto-geradas, não editar)
├── docker/             # Dockerfiles customizados
├── docs/               # Documentação MkDocs Material (EN + PT)
├── makefiles/          # Módulos Makefile específicos de serviços
├── templates/          # Templates de configuração
├── .env                # Variáveis de ambiente
├── docker-compose.tier0.yml  # Serviços de fundação
├── docker-compose.tier1.yml  # Serviços de plataforma de dados
└── Makefile            # Orquestração principal
```

## Serviços

### Tier 0 - Fundação

- [**PostgreSQL 17.6**](services/postgres.md) – Armazenamento de metadados relacional
  `postgres:17.6-alpine3.22`

- [**MinIO**](services/minio.md) – Armazenamento de objetos compatível com S3
  `minio/minio:RELEASE.2025-09-07T16-13-09Z`

### Tier 1 - Plataforma de Dados

- [**Hive Metastore 4.1.0**](services/hive.md) – Catálogo do lakehouse
  Imagem customizada: `flumendata/hive:standalone-metastore-4.1.0`

- [**Apache Spark 4.0.1**](services/spark.md) – Motor de computação distribuída
  Imagem customizada: `flumendata/spark:4.0.1-health`

### Tier 2 - Analytics & Desenvolvimento

- [**JupyterLab (Spark 4.0.1)**](services/jupyterlab.md) – IDE PySpark pronta para uso
  Imagem customizada: `flumendata/jupyterlab:spark-4.0.1`

### Tier 3 - SQL & BI

- [**Trino 450**](services/trino.md) – Motor SQL federado
  Imagem: `trinodb/trino:450`

- [**Apache Superset 5.0.0**](services/superset.md) – Dashboards e SQL Lab
  Imagem customizada: `flumendata/superset:5.0.0`

### Serviços Adicionais

- **Coletor de Métricas** – Monitoramento de saúde e métricas do sistema
  Imagem: `python:3.13-slim`

- **API de Upload de Dados** – Serviço de ingestão baseado em FastAPI
  Imagem customizada: `flumendata-upload-api`

## Recursos Principais

### Integração Delta Lake
- Transações ACID em armazenamento de objetos
- Viagem no tempo (consultas históricas)
- Evolução de schema
- Batch e streaming unificados

### Catálogo Hive Metastore
- Namespace de 2 níveis (database.table)
- Backend PostgreSQL para confiabilidade
- Compatível com Spark, Presto, Trino
- API Thrift padrão (porta 9083)

### Cluster Spark
- 1 Master + 2 Workers
- Pré-configurado para Delta Lake
- Integração S3A com MinIO
- Cache Ivy para resolução rápida de dependências

## Comandos Python CLI

### Inicialização
```bash
python3 flumen init          # Configuração completa do ambiente
python3 flumen config        # Gerar todos os arquivos de configuração
python3 flumen up            # Iniciar todos os serviços
```

### Gerenciamento de Serviços
```bash
python3 flumen up --tier 0      # Iniciar serviços de fundação
python3 flumen up --tier 1      # Iniciar serviços de plataforma de dados
python3 flumen down          # Parar todos os serviços
python3 flumen restart       # Reiniciar todos os serviços
```

### Saúde e Validação
```bash
python3 flumen health        # Verificar saúde de todos os serviços
python3 flumen health --tier 0  # Verificar serviços Tier 0
python3 flumen health --tier 1  # Verificar serviços Tier 1
```

### Testes
```bash
python3 flumen test          # Executar todos os testes
python3 flumen test --tier 0    # Testar serviços de fundação
python3 flumen test --tier 1    # Testar serviços de plataforma de dados
```

### Verificação
```bash
python3 flumen verify-hive   # Verificar configuração do Hive Metastore
python3 flumen summary       # Exibir resumo do ambiente
python3 flumen ps            # Mostrar contêineres em execução
```

### Logs
```bash
python3 flumen logs          # Mostrar logs de todos os serviços
python3 flumen logs --tier 0    # Mostrar logs do Tier 0
python3 flumen logs --tier 1    # Mostrar logs do Tier 1
python3 flumen logs --service spark-master    # Mostrar logs do Spark
python3 flumen logs --service hive-metastore     # Mostrar logs do Hive Metastore
```

### Desenvolvimento
```bash
python3 flumen shell-postgres    # Abrir shell do PostgreSQL
python3 flumen shell-spark       # Abrir shell do Spark
python3 flumen shell-pyspark     # Abrir shell do PySpark
python3 flumen shell-spark-sql   # Abrir shell do Spark SQL
python3 flumen shell-mc                # Abrir cliente MinIO
```

### Dashboard & Métricas
```bash
python3 flumen dashboard-collect   # Executar coleta de métricas
python3 flumen dashboard-setup     # Inicializar views de métricas
python3 flumen dashboard-status    # Verificar o status do coletor
```

### Manutenção
```bash
python3 flumen rebuild         # Reconstrói imagens customizadas
python3 flumen clean         # Parar e remover tudo (PERIGOSO)
```

## Convenções

- Todo **código e comentários** estão em **Inglês**
- Configuração é gerada via **CLI Python** em `/config/` - nunca edite arquivos renderizados manualmente
- Cada serviço deve ter **healthcheck**, **volumes nomeados** e configuração estática em `/config/`
- Documentação é mantida em **Inglês** (`docs/*.md`) e **Português** (`docs/*.pt.md`)

## Interfaces Web

Após executar `python3 flumen init`, acesse essas UIs:

- **Interface Spark Master**: http://localhost:8080
- **Console MinIO**: http://localhost:9001 (minioadmin / minioadmin123)
- Buckets: `lakehouse` (tabelas Delta) e `storage` (arquivos para ingestão)
- **JupyterLab**: http://localhost:8888 (execute `python3 flumen token-jupyterlab` para obter o token)
- **Console Trino**: http://localhost:${TRINO_PORT}
- **Superset**: http://localhost:${SUPERSET_PORT} (login: `admin` / `admin123`)

## Roteiro

- ✅ **Tier 0 – Fundação**: PostgreSQL, MinIO
- ✅ **Tier 1 – Plataforma de Dados**: Spark, Hive Metastore, Delta Lake
- ✅ **Tier 2 – Analytics & Desenvolvimento**: JupyterLab
- ✅ **Tier 3 – SQL & BI**: Trino, Superset

## Sistema de Marca

<div class="fd-color-palette">
  <div class="fd-color" data-token="dark">
    <div class="fd-color-swatch"></div>
    <h4>FD Dark</h4>
    <p>#14171C · heróis e superfícies escuras</p>
  </div>
  <div class="fd-color" data-token="teal">
    <div class="fd-color-swatch"></div>
    <h4>FD Teal Deep</h4>
    <p>#157983 · serviços fundacionais</p>
  </div>
  <div class="fd-color" data-token="cyan">
    <div class="fd-color-swatch"></div>
    <h4>FD Cyan</h4>
    <p>#20EFFD · destaques Trino</p>
  </div>
  <div class="fd-color" data-token="orange">
    <div class="fd-color-swatch"></div>
    <h4>FD Orange</h4>
    <p>#FDA931 · JupyterLab</p>
  </div>
  <div class="fd-color" data-token="blue">
    <div class="fd-color-swatch"></div>
    <h4>FD Blue</h4>
    <p>#0082C8 · Superset / BI</p>
  </div>
  <div class="fd-color" data-token="lime">
    <div class="fd-color-swatch"></div>
    <h4>FD Lime</h4>
    <p>#B8E762 · estados saudáveis</p>
  </div>
</div>

### Tipografia

- **Títulos / logotipo:** Space Grotesk (bold/semi-bold)
- **Corpo:** Inter
- **Código:** JetBrains Mono

Os logos vivem em `assets/images/` e o tema Material usa o favicon/logotipo definidos no `mkdocs.yml`.


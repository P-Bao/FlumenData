# Instalação

Este guia mostra como instalar e configurar o FlumenData no seu sistema.

## Pré-requisitos

### Software Obrigatório

- **Docker**: versão 20.10 ou superior
- **Docker Compose**: versão 2.0 ou superior
- **Make**: GNU Make (normalmente já instalado em Linux/macOS)
- **Git**: para clonar o repositório

### Requisitos de Hardware

**Mínimo:**
- 4 núcleos de CPU
- 16 GB de RAM
- 20 GB de espaço em disco

**Recomendado:**
- 8+ núcleos de CPU
- 32 GB de RAM
- 50 GB de espaço em disco (para dados)

### Sistema Operacional

O FlumenData foi testado em:
- Linux (Ubuntu 20.04+, Debian 11+, RHEL 8+)
- macOS (11.0+)
- Windows (via WSL2)

## Passos de Instalação

### 1. Clone o Repositório

```bash
git clone https://github.com/flumendata/flumendata.git
cd flumendata
```

### 2. Verifique o Docker

```bash
# Verificar versão do Docker
docker --version

# Verificar versão do Docker Compose
docker compose version

# Testar se o Docker está em execução
docker ps
```

### 3. Configure as Variáveis de Ambiente

O FlumenData utiliza um arquivo `.env`. Crie-o a partir do template:

```bash
# Se existir .env.example
cp .env.example .env

# Edite com seu editor preferido
nano .env
```

Caso não exista um `.env.example`, o Makefile gera valores padrão. Variáveis comuns:

```bash
# PostgreSQL
POSTGRES_USER=flumen
POSTGRES_PASSWORD=flumen123
POSTGRES_DB=flumendata
POSTGRES_PORT=5432

# MinIO
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=minioadmin123
MINIO_BUCKET=lakehouse

# Hive Metastore
HIVE_METASTORE_URI=thrift://hive-metastore:9083

# Spark
SPARK_MASTER_HOST=spark-master
SPARK_MASTER_PORT=7077

# Delta Lake
DELTA_VERSION=4.0.0
SCALA_BINARY_VERSION=2.13
```

### 4. Inicialize o Ambiente

Execute o processo completo:

```bash
make init
```

Este comando irá:
1. Gerar todos os arquivos de configuração
2. Construir imagens Docker customizadas (Hive, Spark)
3. Iniciar os serviços do Tier 0 (PostgreSQL, MinIO)
4. Inicializar os buckets do MinIO
5. Iniciar os serviços do Tier 1 (Hive Metastore, cluster Spark)
6. Executar health checks
7. Mostrar o resumo do ambiente

**Saída esperada:**
```
[config] Generating all configuration files...
[tier0] Starting foundation services...
[tier0] All services healthy
[minio] Creating lakehouse bucket...
[tier1] Starting data platform services...
[tier1] All services healthy
[summary] Environment is ready!
```

### 5. Verifique a Instalação

Confirme que todos os serviços estão em execução:

```bash
# Ver containers
make ps

# Health check
make health

# Resumo do ambiente
make summary
```

### 6. Acesse as Interfaces Web

Abra o navegador e visite:

- **Spark Master UI**: http://localhost:8080
- **MinIO Console**: http://localhost:9001
  - Usuário: `minioadmin`
  - Senha: `minioadmin123`

## Pós-Instalação

### Teste a Instalação

Execute os testes para validar tudo:

```bash
# Testar todos os serviços
make test

# Testar tiers específicos
make test-tier0    # PostgreSQL, MinIO
make test-tier1    # Hive Metastore, Spark
```

### Crie Seu Primeiro Banco

```bash
# Abrir shell do Spark SQL
make shell-spark-sql

# Criar banco
CREATE DATABASE my_database
LOCATION 's3a://lakehouse/warehouse/my_database.db';

# Confirmar
SHOW DATABASES;
```

## Solução de Problemas

### Docker permission denied

Se aparecer erro de permissão:

```bash
# Adicionar usuário ao grupo docker (Linux)
sudo usermod -aG docker $USER
newgrp docker

# Validar
docker ps
```

### Porta já em uso

Se alguma porta estiver ocupada, ajuste o `.env`:

```bash
# Exemplo: trocar porta do PostgreSQL
POSTGRES_PORT=5433

# Regenerar configuração
make config

# Reiniciar serviços
make restart
```

# Referência CLI

O FlumenData fornece uma CLI completa baseada em Python para gerenciar o ambiente do lakehouse.

## Referência Rápida

```bash
python3 flumen init              # Inicialização completa (recomendado para primeira execução)
python3 flumen health            # Checar saúde de todos os serviços
python3 flumen ps                # Mostrar containers em execução
python3 flumen summary           # Mostrar resumo do ambiente
python3 flumen logs              # Ver logs de todos os serviços
python3 flumen restart           # Reiniciar todos os serviços
python3 flumen clean             # Parar e remover tudo (DESTRUTIVO)
python3 flumen dashboard-collect # Executar coleta de métricas
```

## Instalação & Pré-requisitos

A CLI do FlumenData requer:
- **Python 3.6+** (pré-instalado no Linux/macOS, instalar via Microsoft Store no Windows)
- **Docker** 20.10+
- **Docker Compose** 2.0+

## Estrutura de Comandos

```bash
python3 flumen <comando> [opções]

# Ou use o wrapper Makefile opcional:
make <comando>
```

## Comandos de Inicialização

### `python3 flumen init`
Inicialização completa do ambiente - recomendado para primeira execução.

**O que faz:**
1. Carrega variáveis de ambiente do `.env`
2. Inicializa diretórios de dados
3. Gera todos os arquivos de configuração
4. Inicia serviços Tier 0 (PostgreSQL, MinIO)
5. Verifica saúde do Tier 0 e inicializa buckets MinIO
6. Inicia serviços Tier 1 (Hive Metastore, Spark)
7. Verifica saúde do Tier 1 e inicializa Hive
8. Exibe resumo do ambiente

**Uso:**
```bash
python3 flumen init

# Pular exibição do banner
python3 flumen init --skip-banner
```

### `python3 flumen init-dirs`
Inicializa apenas os diretórios de dados.

**Uso:**
```bash
python3 flumen init-dirs
```

### `python3 flumen config`
Gera todos os arquivos de configuração a partir de templates.

**Uso:**
```bash
# Gerar todas as configurações
python3 flumen config

# Gerar configuração de serviço específico
python3 flumen config --service minio
python3 flumen config --service hive
python3 flumen config --service spark
python3 flumen config --service jupyterlab
python3 flumen config --service trino
python3 flumen config --service superset
```

**Quando usar:**
- Após modificar arquivo `.env`
- Após atualizar arquivos de template
- Quando arquivos de configuração estiverem faltando

## Gerenciamento de Serviços

### Iniciando Serviços

#### `python3 flumen up`
Inicia todos os serviços (Tiers 0 a 3).

```bash
python3 flumen up
```

#### `python3 flumen up --tier <N>`
Inicia serviços de tier específico.

```bash
python3 flumen up --tier 0  # PostgreSQL, MinIO
python3 flumen up --tier 1  # Hive Metastore, cluster Spark
python3 flumen up --tier 2  # JupyterLab
python3 flumen up --tier 3  # Trino, Superset
```

#### `python3 flumen up --services <serviço1> <serviço2>`
Inicia serviços específicos.

```bash
python3 flumen up --services spark-master spark-worker1
```

### Parando Serviços

#### `python3 flumen down`
Para todos os serviços (containers removidos, volumes preservados).

```bash
python3 flumen down
```

### Reiniciando Serviços

#### `python3 flumen restart`
Reinicia todos os serviços.

```bash
python3 flumen restart
```

## Verificações de Saúde

### `python3 flumen health`
Verifica o status de saúde de todos os serviços.

**Uso:**
```bash
# Verificar todos os serviços
python3 flumen health

# Verificar tier específico
python3 flumen health --tier 0
python3 flumen health --tier 1
python3 flumen health --tier 2
python3 flumen health --tier 3
```

**Saída:**
```
=== Tier 0 - Serviços de Fundação ===
✓ postgres está saudável
✓ minio está saudável

=== Tier 1 - Plataforma de Dados ===
✓ hive-metastore está saudável
✓ spark-master está saudável
✓ spark-worker1 está saudável
✓ spark-worker2 está saudável
```

## Comandos de Teste

### `python3 flumen test`
Executa todos os testes de integração.

**Uso:**
```bash
# Testar todos os serviços
python3 flumen test

# Testar tier específico
python3 flumen test --tier 0
python3 flumen test --tier 1
python3 flumen test --tier 2
python3 flumen test --tier 3

# Executar teste de integração
python3 flumen test --integration
```

**O que testa:**
- PostgreSQL: Conexão, criação de tabelas, persistência de dados
- MinIO: Criação de buckets, upload/download de objetos
- Hive Metastore: Criação de databases, armazenamento de metadados
- Spark: Submissão de jobs, operações Delta Lake
- JupyterLab: Sonda de disponibilidade HTTP
- Trino: Query CLI contra o coordenador

## Comandos de Verificação

### `python3 flumen verify-hive`
Exibe databases e configuração do Hive Metastore.

**Uso:**
```bash
python3 flumen verify-hive
```

### `python3 flumen summary`
Exibe resumo completo do ambiente.

**Uso:**
```bash
python3 flumen summary
```

## Comandos de Logs

### `python3 flumen logs`
Visualiza logs dos serviços.

**Uso:**
```bash
# Todos os serviços (modo follow)
python3 flumen logs

# Tier específico
python3 flumen logs --tier 0
python3 flumen logs --tier 1

# Serviço específico
python3 flumen logs --service spark-master
python3 flumen logs --service hive-metastore

# Sem follow (mostrar logs recentes e sair)
python3 flumen logs --no-follow
python3 flumen logs --service postgres --no-follow
```

## Shells Interativos

### Shells de Banco de Dados

#### `python3 flumen shell-postgres`
Abre shell interativo do PostgreSQL.

**Uso:**
```bash
python3 flumen shell-postgres
```

### Shells Spark

#### `python3 flumen shell-spark`
Abre shell interativo Spark Scala.

**Uso:**
```bash
python3 flumen shell-spark
```

#### `python3 flumen shell-pyspark`
Abre shell interativo PySpark Python.

**Uso:**
```bash
python3 flumen shell-pyspark
```

**Exemplo:**
```python
df = spark.read.format("delta").table("quickstart.customers")
df.show()
```

#### `python3 flumen shell-spark-sql`
Abre shell interativo Spark SQL.

**Uso:**
```bash
python3 flumen shell-spark-sql
```

**Exemplo:**
```sql
SHOW DATABASES;
USE quickstart;
SELECT * FROM customers LIMIT 10;
```

### Cliente MinIO

#### `python3 flumen shell-mc`
Abre cliente MinIO (mc) para operações de object storage.

**Uso:**
```bash
python3 flumen shell-mc

# Listar buckets
mc ls local

# Listar objetos no bucket
mc ls local/lakehouse/warehouse

# Copiar objeto
mc cp local/lakehouse/file.parquet /tmp/

# Criar bucket
mc mb local/bronze
```

## Comandos Específicos de Serviços

### `python3 flumen token-jupyterlab`
Obtém token de acesso do JupyterLab.

**Uso:**
```bash
python3 flumen token-jupyterlab
```

### `python3 flumen superset-db`
Inicializa banco de dados do Superset.

**Uso:**
```bash
python3 flumen superset-db
```

## Comandos de Dashboard & Métricas

### `python3 flumen dashboard-collect`
Executa a coleta de métricas (uma vez) do MinIO, Spark e Delta Lake.

**Uso:**
```bash
python3 flumen dashboard-collect
```

### `python3 flumen dashboard-setup`
Configuração inicial do banco de dados de métricas e views do Trino.

**Uso:**
```bash
python3 flumen dashboard-setup
```

### `python3 flumen dashboard-status`
Mostra o status do coletor de métricas.

**Uso:**
```bash
python3 flumen dashboard-status
```

## Comandos de Limpeza & Manutenção

### `python3 flumen cleanup`
Limpa dados de teste do armazenamento.

**Uso:**
```bash
# Limpar todos os tiers
python3 flumen cleanup

# Limpar tier específico
python3 flumen cleanup --tier 0
python3 flumen cleanup --tier 1
python3 flumen cleanup --tier 2
```

### `python3 flumen clean`
Limpeza completa do ambiente - para serviços e remove todos os dados.

**O que faz:**
1. Solicita confirmação
2. Para todos os serviços
3. Remove todos os containers
4. Remove todos os volumes (dados deletados)
5. Remove redes

**Uso:**
```bash
# Prompt interativo
python3 flumen clean

# Forçar sem confirmação
python3 flumen clean --force
```

!!! danger "Perda de Dados"
    Este comando deleta permanentemente todos os dados armazenados em volumes Docker. Exporte dados importantes antes de executar este comando.

### `python3 flumen rebuild`
Reconstrói todas as imagens Docker customizadas.

**Uso:**
```bash
python3 flumen rebuild
```

### `python3 flumen prune`
Remove recursos Docker não utilizados.

**Uso:**
```bash
python3 flumen prune
```

## Status dos Containers

### `python3 flumen ps`
Mostra containers em execução com status.

**Uso:**
```bash
python3 flumen ps
```

**Alias:**
```bash
python3 flumen status
```

## Tabela de Referência Rápida

| Tarefa | Comando |
|--------|---------|
| Configuração inicial | `python3 flumen init` |
| Verificar tudo | `python3 flumen health` |
| Ver logs | `python3 flumen logs --service spark-master` |
| Reiniciar após mudança de config | `python3 flumen config && python3 flumen restart` |
| Executar testes | `python3 flumen test` |
| Abrir Spark SQL | `python3 flumen shell-spark-sql` |
| Abrir PySpark | `python3 flumen shell-pyspark` |
| Ver ambiente | `python3 flumen summary` |
| Limpeza completa | `python3 flumen clean` |

## Usando o Wrapper Makefile

Por conveniência, todos os comandos têm aliases no Makefile:

```bash
# Estes são equivalentes:
python3 flumen init
make init

python3 flumen health
make health

python3 flumen up --tier 0
make up-tier0
```

O Makefile simplesmente delega para a CLI Python, então você pode usar o que preferir.

## Uso Avançado

### Comandos Sequenciais

```bash
# Fluxo típico após alterar .env
python3 flumen config && python3 flumen restart && python3 flumen health
```

### Compatibilidade Multi-Plataforma

A CLI Python funciona identicamente em:
- **Linux**: Python 3 nativo
- **macOS**: Python 3 nativo
- **Windows**: Python 3 da Microsoft Store ou python.org
- **WSL2**: Python 3 nativo

Sem necessidade de workarounds específicos de plataforma!

## Obtendo Ajuda

### `python3 flumen --help`
Mostra ajuda geral e todos os comandos disponíveis.

```bash
python3 flumen --help
```

### `python3 flumen <comando> --help`
Mostra ajuda para comando específico.

```bash
python3 flumen up --help
python3 flumen test --help
python3 flumen logs --help
```

### `python3 flumen --version`
Mostra versão do FlumenData.

```bash
python3 flumen --version
```

### Sem Comando (Mensagem de Boas-Vindas)
Executar `python3 flumen` sem comando mostra uma mensagem amigável com guia de início rápido.

```bash
python3 flumen
```

## Próximos Passos

- [Variáveis de Ambiente](environment.md) - Configurar serviços
- [Arquitetura](../getting-started/architecture.md) - Entender componentes
- [Guia de Testes](../development/testing.md) - Escrever testes de integração

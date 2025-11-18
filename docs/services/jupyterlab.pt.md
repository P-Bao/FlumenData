# JupyterLab

O JupyterLab serve como ambiente de desenvolvimento interativo para o FlumenData, fornecendo notebooks, exploração de dados e integração direta com o cluster Spark.

## Visão Geral

**Imagem**: `flumendata/jupyterlab:spark-4.0.1` (construída customizada)
**Base**: `jupyter/scipy-notebook:python-3.10`
**Porta**: 8888 (UI Web)
**Python**: 3.10
**PySpark**: 4.0.1 (corresponde ao cluster)
**Delta Lake**: 4.0.0 (corresponde ao cluster)

## Arquitetura

O JupyterLab fornece:
- **Notebooks Interativos**: Notebooks Jupyter com kernels Python, PySpark e SQL
- **Integração Spark**: Conexão direta ao cluster Spark FlumenData (modo cliente)
- **Suporte Delta Lake**: Leitura e escrita de tabelas Delta com garantias ACID
- **Acesso Hive Metastore**: Consulta e gerenciamento de bancos e tabelas
- **Integração S3/MinIO**: Acesso direto ao armazenamento data lake
- **Stack Data Science**: pandas, matplotlib, seaborn, plotly para análise e visualização

## Comandos Make

```bash
# Construir e iniciar
make build-jupyterlab        # Construir imagem customizada JupyterLab
make up-tier2                # Iniciar JupyterLab e outros serviços Tier 2

# Acesso
make token-jupyterlab        # Obter token de acesso JupyterLab
make logs-jupyterlab         # Ver logs do JupyterLab

# Desenvolvimento
make shell-jupyterlab        # Abrir shell bash
make python-jupyterlab       # Abrir shell Python

# Testes
make test-jupyterlab         # Testar integração Spark
make health-jupyterlab       # Verificar saúde do serviço

# Gerenciamento
make restart-jupyterlab      # Reiniciar serviço
make down-tier2              # Parar serviços Tier 2
```

## Primeiros Passos

### 1. Iniciar JupyterLab

```bash
make up-tier2
```

### 2. Obter Token de Acesso

```bash
make token-jupyterlab
```

### 3. Acessar UI Web

Abra http://localhost:8888 e digite o token.

## Usando PySpark em Notebooks

### Criar Sessão Spark

```python
from pyspark.sql import SparkSession

# Criar sessão Spark conectada ao cluster FlumenData
spark = SparkSession.builder \
    .appName("JupyterLab-Notebook") \
    .master("spark://spark-master:7077") \
    .config("spark.submit.deployMode", "client") \
    .config("spark.driver.memory", "2g") \
    .getOrCreate()

# Verificar conexão
print(f"Versão Spark: {spark.version}")
print(f"Implementação de catálogo: {spark.conf.get('spark.sql.catalogImplementation')}")
```

### Trabalhando com Bancos de Dados e Tabelas

```python
# Mostrar bancos de dados disponíveis
spark.sql("SHOW DATABASES").show()

# Criar um novo banco de dados
spark.sql("CREATE DATABASE IF NOT EXISTS analytics")

# Usar o banco de dados
spark.sql("USE analytics")

# Criar uma tabela Delta
spark.sql("""
    CREATE TABLE IF NOT EXISTS customers (
        customer_id INT,
        name STRING,
        email STRING,
        country STRING,
        signup_date DATE,
        lifetime_value DECIMAL(10,2)
    ) USING DELTA
    LOCATION 's3a://lakehouse/warehouse/analytics.db/customers'
""")

# Inserir dados de exemplo
spark.sql("""
    INSERT INTO customers VALUES
    (1, 'Alice Smith', 'alice@example.com', 'USA', '2024-01-15', 1250.50),
    (2, 'Bob Johnson', 'bob@example.com', 'Canada', '2024-02-20', 890.25),
    (3, 'Carol Davis', 'carol@example.com', 'UK', '2024-03-10', 2100.00)
""")

# Consultar dados
df = spark.sql("SELECT * FROM customers WHERE lifetime_value > 1000")
df.show()
```

### API DataFrame

```python
from pyspark.sql.functions import col, avg, count, sum as spark_sum

# Ler tabela Delta como DataFrame
customers_df = spark.table("analytics.customers")

# Exploração de dados
customers_df.printSchema()
customers_df.describe().show()

# Agregações
country_stats = customers_df.groupBy("country") \
    .agg(
        count("*").alias("customer_count"),
        avg("lifetime_value").alias("avg_ltv"),
        spark_sum("lifetime_value").alias("total_ltv")
    ) \
    .orderBy(col("total_ltv").desc())

country_stats.show()
```

### Viagem no Tempo com Delta Lake

```python
# Ver histórico da tabela
spark.sql("DESCRIBE HISTORY analytics.customers").show(truncate=False)

# Consultar em timestamp específico
df_yesterday = spark.read \
    .format("delta") \
    .option("timestampAsOf", "2024-11-09 10:00:00") \
    .table("analytics.customers")

# Consultar versão específica
df_v0 = spark.read \
    .format("delta") \
    .option("versionAsOf", 0) \
    .table("analytics.customers")

# Restaurar tabela para versão anterior
spark.sql("RESTORE TABLE analytics.customers TO VERSION AS OF 2")
```

## Análise de Dados e Visualização

### Usando pandas

```python
# Converter DataFrame Spark para pandas
pandas_df = spark.table("analytics.customers").toPandas()

# Análise pandas
print(pandas_df.describe())
print(pandas_df.groupby('country')['lifetime_value'].mean())
```

### Visualização

```python
import matplotlib.pyplot as plt
import seaborn as sns

# Definir estilo
sns.set_theme(style="whitegrid")

# Consultar dados
df = spark.sql("""
    SELECT country, COUNT(*) as customer_count, AVG(lifetime_value) as avg_ltv
    FROM analytics.customers
    GROUP BY country
""").toPandas()

# Criar gráficos
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 5))

# Gráfico de barras
sns.barplot(data=df, x='country', y='customer_count', ax=ax1)
ax1.set_title('Clientes por País')
ax1.set_ylabel('Contagem de Clientes')

# LTV Médio
sns.barplot(data=df, x='country', y='avg_ltv', ax=ax2)
ax2.set_title('Valor Médio de Lifetime por País')
ax2.set_ylabel('LTV Médio ($)')

plt.tight_layout()
plt.show()
```

## Pacotes Python Instalados

O JupyterLab vem com uma stack completa de ciência de dados:

**Core:**
- pyspark 4.0.1
- delta-spark 4.0.0

**Processamento de Dados:**
- pandas 2.2.2
- pyarrow 16.1.0

**Visualização:**
- matplotlib 3.9.0
- seaborn 0.13.2
- plotly 5.22.0

**Armazenamento:**
- boto3 1.34.144
- s3fs 2024.6.1

**Banco de Dados:**
- psycopg2-binary 2.9.9
- sqlalchemy 2.0.31

**Jupyter:**
- jupyterlab-git 0.50.1
- ipywidgets 8.1.3

## Armazenamento Persistente

Notebooks e arquivos são armazenados no volume nomeado `flumen_jupyter_notebooks` e persistem através de reinicializações do contêiner.

Acessar notebooks em: `/home/jovyan/work`

Diretório de dados compartilhados: `/home/jovyan/shared`

## Solução de Problemas

### Não consegue conectar ao cluster Spark

Verificar se o Spark master está rodando:
```bash
make health-spark-master
```

Verificar conectividade de rede:
```bash
docker exec flumen_jupyterlab nc -zv spark-master 7077
```

### Token de acesso perdido

Recuperar token dos logs:
```bash
make token-jupyterlab
```

Ou da lista de servidores:
```bash
docker exec flumen_jupyterlab jupyter server list
```

## Próximos Passos

- Criar dashboards no [Superset](superset.md)
- Consultar tabelas refinadas via [Trino](trino.md)
- Aprender sobre [otimização Delta Lake](spark.md#performance-tips)

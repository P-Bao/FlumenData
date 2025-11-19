# Início Rápido

Este guia mostra como criar sua primeira tabela Delta Lake e executar consultas no FlumenData.

## Pré-requisitos

Complete o guia de [Instalação](installation.md) e verifique se todos os serviços estão ativos:

```bash
python3 flumen health
```

## Passo 1: Criar um Banco de Dados

Abra o shell do Spark SQL:

```bash
python3 flumen shell-spark-sql
```

Crie o banco:

```sql
CREATE DATABASE quickstart
LOCATION 's3a://lakehouse/warehouse/quickstart.db';

USE quickstart;

SHOW DATABASES;
```

## Passo 2: Criar uma Tabela Delta

Crie uma tabela de clientes:

```sql
CREATE TABLE customers (
  customer_id BIGINT,
  name STRING,
  email STRING,
  signup_date DATE,
  country STRING
) USING DELTA
LOCATION 's3a://lakehouse/warehouse/quickstart.db/customers';
```

Confirme a criação:

```sql
SHOW TABLES;

DESCRIBE EXTENDED customers;
```

## Passo 3: Inserir Dados

```sql
INSERT INTO customers VALUES
  (1, 'Alice Johnson', 'alice@example.com', '2024-01-15', 'USA'),
  (2, 'Bob Smith', 'bob@example.com', '2024-02-20', 'Canada'),
  (3, 'Carlos Garcia', 'carlos@example.com', '2024-03-10', 'Mexico'),
  (4, 'Diana Lee', 'diana@example.com', '2024-04-05', 'USA'),
  (5, 'Eva Mueller', 'eva@example.com', '2024-05-12', 'Germany');
```

Verifique:

```sql
SELECT * FROM customers ORDER BY customer_id;
```

## Passo 4: Consultar os Dados

```sql
-- Total de clientes por país
SELECT country, COUNT(*) as total_customers
FROM customers
GROUP BY country
ORDER BY total_customers DESC;

-- Clientes que se cadastraram no 1º trimestre de 2024
SELECT name, email, signup_date
FROM customers
WHERE signup_date BETWEEN '2024-01-01' AND '2024-03-31'
ORDER BY signup_date;
```

## Passo 5: Atualizar Registros

```sql
-- Atualizar o e-mail de um cliente
UPDATE customers
SET email = 'alice.johnson@newdomain.com'
WHERE customer_id = 1;

-- Conferir o resultado
SELECT * FROM customers WHERE customer_id = 1;
```

## Passo 6: Time Travel

```sql
-- Histórico da tabela
DESCRIBE HISTORY customers;

-- Dados originais (antes do update)
SELECT * FROM customers VERSION AS OF 0;

-- Comparar com a versão atual
SELECT * FROM customers;
```

## Passo 7: Deletar Registros

```sql
DELETE FROM customers WHERE country = 'Germany';

-- Verificar remoção
SELECT * FROM customers ORDER BY customer_id;
```

## Passo 8: Criar Tabela Particionada

```sql
CREATE TABLE orders (
  order_id BIGINT,
  customer_id BIGINT,
  amount DECIMAL(10,2),
  order_date DATE,
  status STRING
) USING DELTA
PARTITIONED BY (DATE(order_date))
LOCATION 's3a://lakehouse/warehouse/quickstart.db/orders';
```

Inserir dados:

```sql
INSERT INTO orders VALUES
  (101, 1, 150.00, '2024-11-01', 'completed'),
  (102, 2, 75.50, '2024-11-01', 'completed'),
  (103, 3, 200.00, '2024-11-02', 'pending'),
  (104, 1, 320.00, '2024-11-03', 'completed'),
  (105, 4, 95.00, '2024-11-03', 'cancelled');
```

Consultar apenas a partição necessária:

```sql
SELECT * FROM orders
WHERE order_date = '2024-11-01';
```

## Passo 9: Fazer Joins

```sql
-- Totais de pedidos por cliente
SELECT
  c.name,
  c.country,
  COUNT(o.order_id) as total_orders,
  SUM(o.amount) as total_spent
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.name, c.country
ORDER BY total_spent DESC;
```

## Passo 10: Explorar com PySpark

Saia do Spark SQL (`Ctrl+D`) e abra o PySpark:

```bash
python3 flumen shell-pyspark
```

Exemplo em Python:

```python
# Ler tabela Delta
df = spark.read.format("delta").table("quickstart.customers")
df.show()

# Filtrar e transformar
from pyspark.sql.functions import year, month

df_with_month = df.withColumn("signup_month", month("signup_date"))
df_with_month.show()

# Escrever outra tabela Delta
df_with_month.write.format("delta") \
    .mode("overwrite") \
    .saveAsTable("quickstart.customers_with_month")

# Conferir
spark.sql("SELECT * FROM quickstart.customers_with_month").show()
```

## Visualizando os Dados no MinIO

As tabelas Delta ficam em arquivos Parquet dentro do MinIO:

1. Abra o console do MinIO: http://localhost:9001
2. Faça login: `minioadmin` / `minioadmin123`
3. Navegue até: `lakehouse` → `warehouse` → `quickstart.db`

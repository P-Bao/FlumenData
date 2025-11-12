flumendata:
  outputs:
    dev:
      type: postgres
      host: postgres
      user: ${POSTGRES_USER}
      password: ${POSTGRES_PASSWORD}
      port: ${POSTGRES_PORT}
      dbname: ${POSTGRES_DB}
      schema: ${DBT_TARGET_SCHEMA}
      threads: ${DBT_THREADS}
      keepalives_idle: 0
      sslmode: disable
      connect_timeout: 10
  target: dev

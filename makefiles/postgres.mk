# postgres.mk - Postgres service targets

config-postgres:
	@echo "[postgres] using container defaults (no custom config needed)."

health-postgres:
	@$(call wait_for_healthy,flumen_postgres,120)

.PHONY: test-postgres persist-postgres config-postgres health-postgres cleanup-postgres

test-postgres:
	@echo "[postgres:test] creating table, inserting rows, selecting..."
	@$(DC) exec -T postgres psql -U $$POSTGRES_USER -d $$POSTGRES_DB -v ON_ERROR_STOP=1 -c "CREATE TABLE IF NOT EXISTS selftest (id serial primary key, note text not null);"
	@$(DC) exec -T postgres psql -U $$POSTGRES_USER -d $$POSTGRES_DB -v ON_ERROR_STOP=1 -c "INSERT INTO selftest(note) VALUES ('hello from flumendata');"
	@$(DC) exec -T postgres psql -U $$POSTGRES_USER -d $$POSTGRES_DB -v ON_ERROR_STOP=1 -c "SELECT id, note FROM selftest ORDER BY id DESC LIMIT 1;"
	@echo "[postgres:test] ok"

persist-postgres:
	@echo "[postgres:persist] restarting container to verify data..."
	@$(DC) restart postgres
	@$(MAKE) health-postgres
	@$(DC) exec -T postgres psql -U $$POSTGRES_USER -d $$POSTGRES_DB -v ON_ERROR_STOP=1 -c "SELECT count(*) AS rows FROM selftest;"
	@echo "[postgres:persist] ok"

cleanup-postgres:
	@$(DC) exec -T postgres psql -U $$POSTGRES_USER -d $$POSTGRES_DB -v ON_ERROR_STOP=1 -c "DROP TABLE IF EXISTS selftest;"
	@echo "[postgres:cleanup] table selftest dropped."
# Contributing to FlumenData

Thank you for your interest in contributing to FlumenData! This guide will help you understand the project structure and development workflow.

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on what is best for the community
- Show empathy towards other community members

## Getting Started

### Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- GNU Make
- Git
- Basic knowledge of: SQL, Python, Docker, Bash

### Development Setup

1. **Fork and clone:**
```bash
git clone https://github.com/YOUR_USERNAME/flumendata.git
cd flumendata
```

2. **Initialize environment:**
```bash
make init
```

3. **Verify everything works:**
```bash
make health
make test
```

## Project Structure

```
/FlumenData/
├── docker/                    # Custom Dockerfiles
│   ├── hive.Dockerfile       # Hive Metastore with PostgreSQL JDBC
│   └── spark.Dockerfile       # Spark with health check utilities
├── makefiles/                 # Service-specific Makefile modules
│   ├── postgres.mk
│   ├── valkey.mk
│   ├── minio.mk
│   ├── hive.mk
│   └── spark.mk
├── templates/                 # Configuration templates
│   ├── hive/
│   ├── spark/
│   ├── minio/
│   └── valkey/
├── docs/                      # MkDocs Material documentation
│   ├── en/                   # English documentation
│   └── pt/                   # Portuguese documentation
├── config/                    # Auto-generated configs (DO NOT EDIT)
├── .env                       # Environment variables (not in git)
├── docker-compose.tier0.yml   # Foundation services
├── docker-compose.tier1.yml   # Data platform services
├── Makefile                   # Main orchestration
└── mkdocs.yml                # Documentation configuration
```

## Development Conventions

### Code Style

**All code and comments MUST be in English:**

```makefile
# ✅ Good
test-postgres:
	@echo "[postgres:test] Running smoke test..."

# ❌ Bad
test-postgres:
	@echo "[postgres:test] Executando teste..."
```

**Documentation:**
- Maintain both English (`docs/en/`) and Portuguese (`docs/pt/`) versions
- Update both versions when making changes

### Configuration Management

**Never edit generated files:**

```bash
# ❌ Wrong - editing generated file
vim config/spark/spark-defaults.conf

# ✅ Correct - edit template and regenerate
vim templates/spark/spark-defaults.conf.tpl
make config-spark
```

**Template structure:**
```properties
# templates/spark/spark-defaults.conf.tpl
spark.master ${SPARK_MASTER_URL}
spark.app.name ${APP_NAME}
```

**Generation:**
```makefile
# makefiles/spark.mk
config/spark/spark-defaults.conf: templates/spark/spark-defaults.conf.tpl
	@mkdir -p $(dir $@)
	$(call render_template,$<,$@)
```

### Makefile Guidelines

**Structure:**

```makefile
# Service-specific makefile (makefiles/service.mk)

# 1. Template definitions
SERVICE_TEMPLATES := templates/service/*.tpl
SERVICE_OUTPUTS := $(patsubst templates/service/%.tpl,config/service/%,$(SERVICE_TEMPLATES))

# 2. Configuration targets
config-service: $(SERVICE_OUTPUTS)
	@echo "[service] config generated."

config/service/%: templates/service/%.tpl
	@mkdir -p $(dir $@)
	$(call render_template,$<,$@)

# 3. Health check targets
health-service:
	@$(call wait_for_healthy,service_container_name,timeout)

# 4. Test targets
test-service:
	@echo "[service:test] Running tests..."
	@docker exec service_container command

# 5. Utility targets
logs-service:
	@$(DC) logs -f service

# 6. PHONY declarations
.PHONY: config-service health-service test-service logs-service
```

**Color codes:**
```makefile
# Use consistent colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
NC := \033[0m  # No Color

target:
	@echo "$(GREEN)[service] Success$(NC)"
	@echo "$(RED)[service] Error$(NC)"
	@echo "$(YELLOW)[service] Warning$(NC)"
```

### Docker Compose Guidelines

**Service definition structure:**

```yaml
services:
  service-name:
    build:
      context: .
      dockerfile: docker/service.Dockerfile
    image: flumendata/service:version
    container_name: flumen_service_name
    restart: unless-stopped
    environment:
      - VAR_NAME=${VAR_NAME}
    ports:
      - "${PORT}:${PORT}"
    depends_on:
      dependency:
        condition: service_healthy
    volumes:
      - service_data:/data/path
      - ./config/service/file.conf:/etc/service/file.conf:ro
    healthcheck:
      test: ["CMD-SHELL", "command to test health"]
      interval: 5s
      timeout: 3s
      retries: 20
      start_period: 60s
    networks:
      - tier_network

volumes:
  service_data:
    name: flumen_service_data

networks:
  tier_network:
    name: flumen_tier_network
```

**Health check best practices:**

```yaml
# ✅ Process check (fast)
healthcheck:
  test: ["CMD-SHELL", "pgrep -f ProcessName > /dev/null || exit 1"]

# ✅ HTTP check
healthcheck:
  test: ["CMD-SHELL", "curl -sf http://localhost:8080/ > /dev/null"]

# ❌ Network check (slow)
healthcheck:
  test: ["CMD-SHELL", "netstat -an | grep 9083"]
```

### Dockerfile Guidelines

**Structure:**

```dockerfile
# Base image (pinned version)
FROM apache/service:1.2.3

# Switch to root for installations
USER root

# Install dependencies
RUN apt-get update && apt-get install -y \
    package1 \
    package2 \
    && rm -rf /var/lib/apt/lists/*

# Download JARs or dependencies
RUN curl -fsSL https://repo.maven.org/.../artifact.jar \
    -o /opt/app/lib/artifact.jar

# Prepare directories with correct permissions
RUN mkdir -p /opt/app/data && \
    chown -R appuser:appgroup /opt/app/data

# Switch back to non-root user
USER appuser

# Set working directory
WORKDIR /opt/app
```

## Contributing Workflow

### 1. Create a Feature Branch

```bash
git checkout -b feature/my-new-feature
```

**Branch naming:**
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation changes
- `refactor/` - Code refactoring
- `test/` - Test additions/changes

### 2. Make Changes

Follow the conventions above and ensure:

- Code is in English
- Configuration uses templates
- Documentation is updated (EN + PT)
- Tests are added/updated

### 3. Test Your Changes

```bash
# Regenerate configuration
make config

# Restart affected services
make restart

# Run health checks
make health

# Run integration tests
make test

# Test specific components
make test-service
```

### 4. Update Documentation

```bash
# Update English docs
vim docs/en/services/my-service.md

# Update Portuguese docs
vim docs/pt/services/my-service.md

# Build docs locally
pip install mkdocs-material
mkdocs serve

# Visit http://localhost:8000
```

### 5. Commit Changes

**Commit message format:**

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Examples:**

```bash
git commit -m "feat(spark): add Delta Lake 4.0 support

- Update spark-defaults.conf template
- Add Delta Lake JAR dependencies
- Update documentation

Closes #123"
```

```bash
git commit -m "fix(hive): correct health check command

Changed from netstat to pgrep for faster startup

Fixes #456"
```

**Types:**
- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation only
- `style` - Formatting changes
- `refactor` - Code refactoring
- `test` - Adding tests
- `chore` - Maintenance tasks

### 6. Push and Create Pull Request

```bash
git push origin feature/my-new-feature
```

Then create a Pull Request on GitHub with:

- Clear description of changes
- Link to related issues
- Screenshots (if UI changes)
- Test results

## Adding a New Service

### 1. Create Dockerfile

```bash
# docker/myservice.Dockerfile
FROM official/image:version
USER root
RUN apt-get update && apt-get install -y curl procps
USER appuser
```

### 2. Create Makefile Module

```bash
# makefiles/myservice.mk
MYSERVICE_TEMPLATES := templates/myservice/*.tpl
MYSERVICE_OUTPUTS := $(patsubst templates/myservice/%.tpl,config/myservice/%,$(MYSERVICE_TEMPLATES))

config-myservice: $(MYSERVICE_OUTPUTS)
	@echo "[myservice] config generated."

config/myservice/%: templates/myservice/%.tpl
	@mkdir -p $(dir $@)
	$(call render_template,$<,$@)

health-myservice:
	@$(call wait_for_healthy,flumen_myservice,120)

test-myservice:
	@echo "[myservice:test] Running tests..."
	# Add test commands

.PHONY: config-myservice health-myservice test-myservice
```

### 3. Add to Docker Compose

```yaml
# docker-compose.tierN.yml
services:
  myservice:
    build:
      context: .
      dockerfile: docker/myservice.Dockerfile
    image: flumendata/myservice:version
    container_name: flumen_myservice
    restart: unless-stopped
    volumes:
      - myservice_data:/data
      - ./config/myservice:/etc/myservice:ro
    healthcheck:
      test: ["CMD-SHELL", "health check command"]
      interval: 5s
      timeout: 3s
      retries: 20

volumes:
  myservice_data:
    name: flumen_myservice_data
```

### 4. Update Main Makefile

```makefile
# Makefile
include makefiles/myservice.mk

config: config-tier0 config-tier1 config-myservice

init-tierN: up-tierN health-tierN init-myservice

health-tierN: health-other health-myservice

test-tierN: test-other test-myservice
```

### 5. Add Documentation

```bash
# docs/en/services/myservice.md
# docs/pt/services/myservice.md
```

Update mkdocs.yml:

```yaml
nav:
  - Services:
      - Tier N:
          - My Service: services/myservice.md
```

### 6. Test Integration

```bash
make config-myservice
make up
make health-myservice
make test-myservice
```

## Testing

See [Testing Guide](testing.md) for detailed testing instructions.

## Getting Help

- GitHub Issues: https://github.com/flumendata/flumendata/issues
- Discussions: https://github.com/flumendata/flumendata/discussions

## License

By contributing, you agree that your contributions will be licensed under the Apache License 2.0.

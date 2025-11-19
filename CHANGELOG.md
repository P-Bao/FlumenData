# Changelog

All notable changes to FlumenData will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Version variables in `.env` for all service versions (SPARK_VERSION, HIVE_VERSION, POSTGRES_VERSION, MINIO_VERSION, SUPERSET_VERSION, TRINO_VERSION)
- WSL-compatible directory creation using `install -d` command
- Automatic CRLF to LF conversion for generated configuration files
- `.gitattributes` file to enforce Unix line endings for shell scripts and templates
- `TROUBLESHOOTING.md` with comprehensive WSL/Docker Desktop issue solutions
- MIT License (Copyright 2025 Luciano Mauda Junior)

### Changed
- Updated all GitHub repository URLs from `github.com/flumendata/flumendata` to `github.com/lucianomauda/FlumenData`
- Centralized version management: all versions now sourced from `.env` instead of hardcoded in Dockerfiles
- Improved Makefile template rendering to handle Windows line endings on WSL
- Updated `DATA_DIR` default to use `/mnt/d/projects/data-projects` for Windows users with more storage space
- Updated JupyterLab dependencies: pandas 2.3.3, added polars 1.35.2

### Fixed
- Docker credentials error on WSL by removing broken credential helper configuration
- Windows CRLF line endings breaking Spark containers
- Directory creation failures on WSL with Windows-mounted drives (`/mnt/d`, `/mnt/c`)
- Version inconsistencies across Dockerfiles and docker-compose files
- Bind mount issues with Docker Desktop on WSL

### Security
- Removed credential helper that could expose credentials in WSL environment

## [1.0.0] - 2025-01-XX (Initial Release)

### Added
- Complete lakehouse platform with Docker Compose orchestration
- Tier 0: PostgreSQL 17.6, MinIO (S3-compatible storage)
- Tier 1: Apache Spark 4.0.1 (1 master + 2 workers), Hive Metastore 4.1.0, Delta Lake 4.0.0
- Tier 2: JupyterLab with PySpark integration
- Tier 3: Trino 450, Apache Superset 5.0.0
- Automated initialization via `make init`
- Health checks for all services
- ACID transactions support via Delta Lake
- Time travel capabilities
- Schema evolution support
- S3A protocol support for MinIO
- Comprehensive documentation in English and Portuguese
- MkDocs documentation site with custom branding
- Example notebooks and SQL scripts
- Data persistence across container restarts

### Documentation
- Quick start guide
- Architecture overview
- Service-specific documentation
- Brand system and visual identity
- Portuguese translations for all documentation

---

## How to Use This Changelog

### When Making Changes

After completing a feature, bug fix, or any notable change:

1. **Open CHANGELOG.md**
2. **Add your change under `[Unreleased]` in the appropriate category:**
   - **Added** - New features
   - **Changed** - Changes to existing functionality
   - **Deprecated** - Features that will be removed soon
   - **Removed** - Removed features
   - **Fixed** - Bug fixes
   - **Security** - Security improvements

3. **Use a clear, user-focused description:**
   ```markdown
   ### Added
   - Support for Apache Iceberg table format
   - New monitoring dashboard for Spark jobs
   ```

### When Creating a Release

1. **Change `[Unreleased]` to version number with date:**
   ```markdown
   ## [1.1.0] - 2025-02-15
   ```

2. **Create a new `[Unreleased]` section at the top:**
   ```markdown
   ## [Unreleased]

   ### Added

   ### Changed

   ### Fixed

   ## [1.1.0] - 2025-02-15
   ```

3. **Commit the changelog with your release**

### Version Numbering (Semantic Versioning)

Format: `MAJOR.MINOR.PATCH`

- **MAJOR** (1.x.x): Breaking changes (incompatible API changes)
- **MINOR** (x.1.x): New features (backward-compatible)
- **PATCH** (x.x.1): Bug fixes (backward-compatible)

Examples:
- `1.0.0` → `1.0.1`: Bug fix release
- `1.0.1` → `1.1.0`: New feature added
- `1.1.0` → `2.0.0`: Breaking change (e.g., removed a service)

[Unreleased]: https://github.com/lucianomauda/FlumenData/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/lucianomauda/FlumenData/releases/tag/v1.0.0

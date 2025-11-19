# Changelog Maintenance Guide

Quick reference for maintaining CHANGELOG.md

## Daily Workflow

### 1. After Making a Change

Open `CHANGELOG.md` and add to the `[Unreleased]` section:

```markdown
## [Unreleased]

### Added
- Your new feature here

### Changed
- Your modification here

### Fixed
- Your bug fix here
```

### 2. Example Entry

```markdown
## [Unreleased]

### Added
- Support for Apache Iceberg tables alongside Delta Lake
- Real-time monitoring dashboard for Spark jobs
- Auto-scaling for Spark workers based on CPU usage

### Changed
- Upgraded Spark from 4.0.1 to 4.0.2
- Improved JupyterLab startup time by 50%

### Fixed
- MinIO bucket creation race condition
- Hive metastore connection timeout on slow networks
```

## Creating a Release

### Step 1: Update Version

Change `[Unreleased]` to the new version with today's date:

```markdown
## [1.1.0] - 2025-02-15
```

### Step 2: Add New Unreleased Section

```markdown
## [Unreleased]

### Added

### Changed

### Fixed

## [1.1.0] - 2025-02-15
(previous changes here)
```

### Step 3: Update Links at Bottom

```markdown
[Unreleased]: https://github.com/lucianomauda/FlumenData/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/lucianomauda/FlumenData/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/lucianomauda/FlumenData/releases/tag/v1.0.0
```

### Step 4: Update .env if Needed

If you changed versions in the release:

```bash
# In .env
SPARK_VERSION=4.0.2  # Updated from 4.0.1
```

### Step 5: Tag and Release

```bash
git add CHANGELOG.md
git commit -m "Release v1.1.0"
git tag -a v1.1.0 -m "Release version 1.1.0"
git push origin main --tags
```

## Version Number Rules

**Format:** `MAJOR.MINOR.PATCH` (e.g., 1.2.3)

| Change | Increment | Example |
|--------|-----------|---------|
| Bug fix | PATCH | 1.0.0 → 1.0.1 |
| New feature (backward-compatible) | MINOR | 1.0.1 → 1.1.0 |
| Breaking change | MAJOR | 1.1.0 → 2.0.0 |

### Breaking Changes Examples:
- Removing a service (e.g., removing Superset)
- Changing default ports
- Removing environment variables
- Incompatible data format changes

### New Features Examples:
- Adding a new service
- Adding new Makefile targets
- Adding new configuration options

### Bug Fixes Examples:
- Fixing broken health checks
- Correcting documentation errors
- Fixing permission issues

## Categories

Use these categories in order:

1. **Added** - New features, new services
2. **Changed** - Modifications to existing features
3. **Deprecated** - Features marked for removal
4. **Removed** - Deleted features
5. **Fixed** - Bug fixes
6. **Security** - Security improvements

## Tips

✓ **Be specific:** "Fixed Spark worker connection timeout" not "Fixed bug"
✓ **User-focused:** Explain the impact, not the code change
✓ **One line per change:** Keep entries concise
✓ **Group related changes:** Put related items together

❌ **Don't include:**
- Internal refactoring (unless it affects performance)
- Dependency updates (unless they fix a bug or add a feature)
- Typo fixes in code comments
- Changes to development tools

## Quick Template

Copy this when starting a new change:

```markdown
## [Unreleased]

### Added
-

### Changed
-

### Fixed
-
```

Save this guide in `.github/CHANGELOG_GUIDE.md` for quick reference!

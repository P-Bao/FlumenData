# FlumenData Storage Configuration

FlumenData uses **configurable bind mounts** for critical user data while keeping everything else in Docker volumes for simplicity.

## 📁 Data Directory Structure

Only **2 directories** are exposed as bind mounts - the ones you actually need access to:

```
${DATA_DIR}/                  # Default: ../data-projects/flumendata
├── minio/                    # MinIO lakehouse storage (can grow to TBs)
│   ├── lakehouse/           # Delta Lake tables
│   └── storage/             # Staging bucket for raw files
└── notebooks/               # JupyterLab notebooks (YOUR WORK - version control this!)
    ├── _examples/           # Read-only example notebooks
    ├── 01_analysis.ipynb   # Your notebooks
    └── .git/               # Optional: init git here
```

Everything else (PostgreSQL metadata, Spark logs, caches) stays in **Docker volumes** - you don't need direct access to them.

## ⚙️ Configuration

### Change Data Location

Edit `.env` and set `DATA_DIR` to your preferred location:

```bash
# Relative path (default)
DATA_DIR=../data-projects/flumendata

# Absolute path
DATA_DIR=/mnt/nas/flumendata

# Home directory
DATA_DIR=~/flumendata-data

# External drive (for TB of lakehouse data)
DATA_DIR=/mnt/external/flumendata
```

### Initialization

Run `make init` to create the directory structure:

```bash
make init
```

This will:
1. Create `minio/` and `notebooks/` directories
2. Set up proper structure
3. Initialize all services

## 📓 Version Control Your Notebooks

The **notebooks/** directory is perfect for version control!

```bash
cd ${DATA_DIR}/notebooks

# Initialize git
git init
git add .
git commit -m "Initial commit: FlumenData analysis notebooks"

# Add remote (GitHub, GitLab, etc.)
git remote add origin https://github.com/yourusername/flumendata-notebooks.git
git push -u origin main
```

### Recommended .gitignore

Create `${DATA_DIR}/notebooks/.gitignore`:

```gitignore
# Jupyter checkpoints
.ipynb_checkpoints/
_examples/

# Python cache
__pycache__/
*.py[cod]

# Large data files (store in MinIO lakehouse bucket instead!)
*.csv
*.parquet
*.xlsx
*.zip
```

## 💾 What to Backup

### Critical (Must Backup)

**1. MinIO Data** - `${DATA_DIR}/minio/`
- Your lakehouse tables (Delta format)
- Can grow to GBs/TBs
- This is your actual data warehouse!

**2. Notebooks** - `${DATA_DIR}/notebooks/`
- Your analysis work
- SQL queries, explorations, reports
- **Better solution**: Use git to version control

### Metadata (Handled by Docker Volumes)

These are in Docker volumes - backup if you want, but less critical:
- PostgreSQL data (`flumen_postgres_data`) - Hive Metastore catalog
- Superset home (`flumen_superset_home`) - Dashboards config
- Spark logs (`flumen_spark_logs`) - Debug logs

### Backup Commands

```bash
# Backup MinIO + Notebooks (the important stuff)
tar -czf flumendata-backup-$(date +%Y%m%d).tar.gz ${DATA_DIR}

# Rsync to NAS
rsync -av --progress ${DATA_DIR}/ /mnt/nas/backups/flumendata/

# Or just use git for notebooks
cd ${DATA_DIR}/notebooks
git add .
git commit -m "Latest analysis"
git push
```

## 🔄 Migration

### Moving to Different Machine

1. **Export data:**
```bash
cd $(dirname ${DATA_DIR})
tar -czf flumendata-data.tar.gz flumendata/
```

2. **On new machine:**
```bash
cd /new/location
tar -xzf flumendata-data.tar.gz
```

3. **Update `.env`:**
```bash
DATA_DIR=/new/location/flumendata
```

4. **Restart:**
```bash
make down
make up
make health
```

### Moving MinIO to Larger Disk

If your lakehouse grows too large:

```bash
# Stop services
make down

# Move MinIO data
rsync -av --progress ${DATA_DIR}/minio/ /mnt/larger-disk/minio/

# Update .env
DATA_DIR=/mnt/larger-disk

# Restart
make up
```

## 🚀 Best Practices

### Recommended Workflow

1. **Store raw data** in MinIO `storage` bucket (via web UI or mc client)
2. **Process with Spark** and save as Delta tables in `lakehouse` bucket
3. **Explore in JupyterLab** notebooks (save your .ipynb files!)
4. **Query with Trino** for ad-hoc SQL
5. **Visualize in Superset** for dashboards

### For Your Notebooks

```bash
# Good workflow
cd ${DATA_DIR}/notebooks
git init
git remote add origin git@github.com:you/your-analysis.git

# Regular workflow
vim analysis.ipynb  # or use JupyterLab
git add analysis.ipynb
git commit -m "Add customer segmentation analysis"
git push
```

### Storage Tips

- **SSD** for `${DATA_DIR}` if possible (better performance)
- **HDD** is OK for MinIO if budget-constrained (works fine, just slower)
- **Monitor disk usage**: `du -sh ${DATA_DIR}/*`
- **Clean old Spark logs** in Docker volumes: `docker volume rm flumen_spark_logs`

## 📊 Docker Volumes (No Direct Access Needed)

These remain as Docker volumes for simplicity:

| Volume | Purpose | Location |
|--------|---------|----------|
| `flumen_postgres_data` | Hive Metastore catalog | `/var/lib/docker/volumes/` |
| `flumen_spark_conf` | Spark config cache | `/var/lib/docker/volumes/` |
| `flumen_spark_ivy` | Maven/Ivy dependencies | `/var/lib/docker/volumes/` |
| `flumen_spark_work` | Temporary work files | `/var/lib/docker/volumes/` |
| `flumen_spark_logs` | Spark logs | `/var/lib/docker/volumes/` |
| `flumen_superset_home` | Superset dashboards | `/var/lib/docker/volumes/` |

To clean up volumes:
```bash
make down
docker volume prune  # Remove unused volumes
```

## 🆘 Troubleshooting

### Permission Issues

If JupyterLab can't write to notebooks:

```bash
# Fix permissions (JupyterLab runs as UID 1000)
sudo chown -R 1000:1000 ${DATA_DIR}/notebooks
```

For MinIO:
```bash
# MinIO needs write access
sudo chown -R $USER:$USER ${DATA_DIR}/minio
```

### Directory Not Found

```bash
# Manually create if needed
make init-data-dirs
```

Or:
```bash
mkdir -p ${DATA_DIR}/{minio/{lakehouse,storage},notebooks/_examples}
```

### Disk Full

Check what's using space:
```bash
du -sh ${DATA_DIR}/*
```

Clean up MinIO staging:
```bash
# Via MinIO console (http://localhost:9001)
# Delete files from 'storage' bucket

# Or via mc client
make mc
mc rm --recursive --force flumen/storage/old-data/
```

## 📖 See Also

- [Configuration Guide](docs/configuration/environment.md)
- [MinIO Documentation](docs/services/minio.md)
- [JupyterLab Guide](docs/services/jupyterlab.md)
- [Main README](README.md)

# FlumenData Storage Configuration

FlumenData uses **configurable bind mounts** for critical user data while keeping everything else in Docker volumes for simplicity.

[Este guia também está disponível em Português](./DATA_STORAGE_PT.md)

## 📁 Data Directory Structure

Only **2 directories** are exposed as bind mounts - the ones you actually need access to:

```
${DATA_DIR}/                  # Default: ../flumendata-data (sibling to FlumenData repo)
├── minio/                    # MinIO lakehouse storage (can grow to TBs)
│   ├── lakehouse/           # Delta Lake tables
│   └── storage/             # Staging bucket for raw files
└── notebooks/               # JupyterLab notebooks (YOUR WORK - version control this!)
    ├── _examples/           # Read-only example notebooks
    ├── 01_analysis.ipynb   # Your notebooks
    └── .git/               # Optional: init git here
```

Everything else (PostgreSQL metadata, Spark logs, caches) stays in **Docker volumes** - you don't need direct access to them.

## 🪟 Initial Setup (WSL + Windows)

### Step 1: Create Base Directory on Windows

**IMPORTANT:** When using WSL with Windows drives, create the base directory from Windows first.

**Method 1 - File Explorer (Recommended):**
1. Press `Win + E` to open File Explorer
2. Navigate to `This PC` → `D:` drive
3. Right-click in empty space → `New` → `Folder`
4. Name it: `data-projects`

**Method 2 - PowerShell:**
```powershell
New-Item -ItemType Directory -Path "D:\data-projects" -Force
```

**Method 3 - Command Prompt:**
```cmd
mkdir D:\data-projects
```

### Step 2: Initialize Data Directories

From WSL, run:
```bash
make init-data-dirs
```

This will create the subdirectories:
- `minio/lakehouse`
- `minio/storage`
- `notebooks/_examples`

### Step 3: Complete Initialization

```bash
make init
```

This will:
1. ✓ Verify data directories exist
2. ✓ Generate all configuration files
3. ✓ Start all services
4. ✓ Initialize databases and buckets

## ⚙️ Configuration

### Data Location

**Default:** `DATA_DIR=../flumendata-data` (relative path - sibling directory to FlumenData)

This creates the structure:
```
your-workspace/
├── FlumenData/          # This repository (git clone)
└── flumendata-data/     # Your data (can be separate git repo)
    ├── minio/
    └── notebooks/
```

### Change Data Location

Edit `.env` and set `DATA_DIR` to your preferred location:

**Option 1: Relative paths (RECOMMENDED - portable across machines)**
```bash
# Sibling directory (default)
DATA_DIR=../flumendata-data

# Inside project (simple but mixes code and data)
DATA_DIR=./data

# Parent directory with custom name
DATA_DIR=../../my-lakehouse-data
```

**Option 2: Absolute paths (machine-specific)**
```bash
# Windows D: drive (WSL path - accessible from Windows Explorer)
DATA_DIR=/mnt/d/data-projects

# Windows E: drive
DATA_DIR=/mnt/e/flumendata

# Windows C: drive (Users folder)
DATA_DIR=/mnt/c/Users/YourName/flumendata

# Linux home directory
DATA_DIR=~/flumendata-data

# Linux absolute path
DATA_DIR=/home/user/flumendata

# Network storage
DATA_DIR=/mnt/nas/flumendata
```

**Trade-offs:**
- **Relative paths:** Portable, work anywhere you clone FlumenData, easier for teams
- **Absolute paths:** Always work regardless of current directory, explicit location

## 📓 Version Control Your Notebooks

The **notebooks/** directory is perfect for version control!

```bash
cd /mnt/d/data-projects/notebooks

# Initialize git
git init
git add .
git commit -m "Initial commit: FlumenData analysis notebooks"

# Add remote (GitHub, GitLab, etc.)
git remote add origin https://github.com/yourusername/flumendata-notebooks.git
git push -u origin main
```

### Recommended .gitignore

Create `/mnt/d/data-projects/notebooks/.gitignore`:

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
# From Windows: Just copy D:\data-projects folder

# From WSL:
tar -czf flumendata-backup-$(date +%Y%m%d).tar.gz /mnt/d/data-projects

# Rsync to NAS
rsync -av --progress /mnt/d/data-projects/ /mnt/nas/backups/flumendata/

# Or just use git for notebooks
cd /mnt/d/data-projects/notebooks
git add .
git commit -m "Latest analysis"
git push
```

## 🔄 Migration

### Moving to Different Machine

#### Option 1: Windows to Windows (Copy via Windows)

1. **Copy folder in Windows:**
   - Copy `D:\data-projects` to USB drive or network
   - On new machine, paste to `D:\data-projects`

2. **Clone FlumenData repo on new machine:**
```bash
git clone https://github.com/flumendata/flumendata.git
cd flumendata
```

3. **Copy `.env` or set DATA_DIR:**
```bash
# In .env
DATA_DIR=/mnt/d/data-projects
```

4. **Start services:**
```bash
make init
```

#### Option 2: Linux to Linux (Tar backup)

1. **Export data:**
```bash
cd $(dirname ${DATA_DIR})
tar -czf flumendata-data.tar.gz data-projects/
```

2. **On new machine:**
```bash
cd /new/location
tar -xzf flumendata-data.tar.gz
```

3. **Update `.env`:**
```bash
DATA_DIR=/new/location/data-projects
```

4. **Restart:**
```bash
make init
```

### Moving MinIO to Larger Disk

If your lakehouse grows too large:

```bash
# Stop services
make down

# Copy data to new location (from Windows Explorer or WSL)
# Windows: Copy D:\data-projects\minio to E:\data-projects\minio
# Or from WSL:
rsync -av --progress /mnt/d/data-projects/minio/ /mnt/e/data-projects/minio/

# Update .env
DATA_DIR=/mnt/e/data-projects

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
cd /mnt/d/data-projects/notebooks
git init
git remote add origin git@github.com:you/your-analysis.git

# Regular workflow
vim analysis.ipynb  # or use JupyterLab
git add analysis.ipynb
git commit -m "Add customer segmentation analysis"
git push
```

### Storage Tips

- **Keep on Windows drive** for easy access and backup
- **Monitor disk usage**: Right-click D:\data-projects → Properties
- **Use Windows tools** for backup (OneDrive, Dropbox, etc.)
- **SSD preferred** for better performance (but HDD works fine)

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

### "Directory does not exist" Error

If you get an error when running `make init-data-dirs`:

```
[init] ✗ Directory /mnt/d/data-projects does not exist
```

**Solution:** Create the base directory from Windows first (see "Initial Setup" above).

**Why?** WSL cannot create directories at the Windows drive root level. You must create `D:\data-projects` from Windows, then FlumenData can create subdirectories inside it.

### Permission Issues

If JupyterLab can't write to notebooks:

```bash
# Fix permissions (JupyterLab runs as UID 1000)
sudo chown -R 1000:1000 /mnt/d/data-projects/notebooks
```

For MinIO:
```bash
# MinIO needs write access
sudo chown -R $USER:$USER /mnt/d/data-projects/minio
```

### Cannot Access from Windows

If you can't see the data from Windows Explorer:

```bash
# Verify the path from WSL
ls -la /mnt/d/data-projects

# Open in Windows Explorer from WSL
explorer.exe /mnt/d/data-projects
```

Or directly open: `D:\data-projects` in File Explorer

### Disk Full

Check what's using space:

**From Windows:**
- Right-click `D:\data-projects` → Properties

**From WSL:**
```bash
du -sh /mnt/d/data-projects/*
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

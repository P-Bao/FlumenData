# Troubleshooting Guide

## Windows WSL Issues

### Docker Credentials Error

**Symptom:**
```
error getting credentials - err: exit status 1, out: ``
```

**Cause:**
Docker Desktop credential helper (`desktop.exe`) isn't accessible from WSL.

**Solution:**
```bash
# Backup and reset Docker config
cp ~/.docker/config.json ~/.docker/config.json.backup
echo '{}' > ~/.docker/config.json
```

This removes the credential helper. Since you're pulling public images, no authentication is needed.

### Windows Line Endings in Config Files

**Symptom:**
```
/opt/spark/conf/spark-env.sh: line 9: $'\r': command not found
java.lang.NumberFormatException: For input string: "7077"
```

**Cause:**
Git on Windows checks out files with CRLF line endings, which breaks shell scripts in Linux containers.

**Solution:**
The Makefile now automatically converts line endings when generating configs. If you manually edited template files:

```bash
# Convert all templates to Unix line endings
find templates/ -type f -exec sed -i 's/\r$//' {} \;

# Regenerate configs
make down
make config
make up
```

**Prevention:**
Add to `.gitattributes` in your project root:
```
*.sh text eol=lf
*.tpl text eol=lf
```

## Docker Desktop on Windows WSL Issues

### Bind Mount Error: "no such file or directory"

**Symptom:**
```
Error response from daemon: failed to create task for container: failed to create shim task:
OCI runtime create failed: runc create failed: unable to start container process:
error during container init: error mounting "/run/desktop/mnt/host/wsl/docker-desktop-bind-mounts/..."
```

**Cause:**
Docker Desktop on WSL caches bind mount metadata. When directories are created/recreated, the cache becomes stale.

**Solution:**

1. **Stop all containers:**
   ```bash
   make down
   # or
   docker compose -f docker-compose.tier0.yml down -v
   ```

2. **Restart Docker Desktop:**
   - Right-click Docker Desktop icon in Windows system tray
   - Click "Quit Docker Desktop"
   - Start Docker Desktop again
   - Wait for it to fully start (whale icon stops animating)

3. **Alternative - Restart WSL (more thorough):**
   ```powershell
   # From PowerShell (as Administrator):
   wsl --shutdown
   ```
   Then restart your WSL terminal and Docker Desktop

4. **Run init again:**
   ```bash
   make init
   ```

### Directory Creation Issues on WSL

**Symptom:**
```
mkdir: cannot create directory '/mnt/d/...': File exists
```
But the directory doesn't actually exist.

**Solution:**
The Makefile now uses `install -d` instead of `mkdir -p` which handles this WSL quirk automatically. If you still see this:

1. Update to the latest Makefile
2. Ensure `DATA_DIR` in `.env` uses a native WSL path:
   ```bash
   # Good (native WSL filesystem):
   DATA_DIR=/home/username/projects/data-projects

   # Can have issues (Windows-mounted drive):
   DATA_DIR=/mnt/d/projects/data-projects
   ```

### Performance: Slow File I/O

**Symptom:**
Slow performance when data is on Windows drives (`/mnt/c`, `/mnt/d`, etc.)

**Solution:**
Use native WSL filesystem for better performance:

```bash
# In .env:
DATA_DIR=/home/luciano/projects/data-projects
```

**Note:** Data in `/home/luciano` is stored in WSL's virtual disk (ext4), which is much faster than Windows NTFS via `/mnt/d`.

To access from Windows Explorer:
```
\\wsl$\Ubuntu-24.04\home\luciano\projects\data-projects
```

### Container Won't Start After System Restart

**Symptom:**
Containers fail to start after Windows restart with network or volume errors.

**Solution:**

1. Restart Docker Desktop
2. If that doesn't work:
   ```bash
   make down
   docker system prune -f
   make init
   ```

### Port Already in Use

**Symptom:**
```
Error: Bind for 0.0.0.0:9000 failed: port is already allocated
```

**Solution:**

1. Check what's using the port:
   ```bash
   # Linux/WSL:
   sudo lsof -i :9000

   # Or check Docker:
   docker ps -a
   ```

2. Stop the conflicting service or change the port in `.env`:
   ```bash
   MINIO_PORT_API=9010  # Change from default 9000
   ```

## General Tips

### Check Service Health
```bash
make health          # Check all services
make health-tier0    # Check foundation services only
docker ps            # See running containers
```

### View Logs
```bash
make logs            # All services
make logs-minio      # Specific service
make logs-tier0      # Tier 0 services
```

### Complete Reset
If everything is broken:
```bash
make down
docker system prune -af  # WARNING: Removes all unused Docker data
rm -rf /home/luciano/projects/data-projects  # Or your DATA_DIR
make init
```

### WSL Performance Best Practices

1. **Use native WSL filesystem** (`/home/...`) for data directories
2. **Keep project code on Windows** (`/mnt/d/projects/...`) for easy editing
3. **Docker volumes use native storage** automatically

## Still Having Issues?

1. Check Docker Desktop is running and up to date
2. Ensure WSL 2 is installed: `wsl --status`
3. Check disk space: `df -h`
4. Review logs: `make logs`
5. Open an issue with:
   - Output of `make init`
   - Output of `docker version`
   - Output of `wsl --status`

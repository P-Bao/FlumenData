# Configuração de Armazenamento do FlumenData

[Leia este guia em inglês](./DATA_STORAGE.md)

O FlumenData utiliza **bind mounts configuráveis** para os dados do usuário e mantém o restante em volumes Docker para simplificar.

## 📁 Estrutura do Diretório de Dados

Apenas **2 diretórios** são expostos via bind mount — exatamente aqueles que você precisa acessar:

```
${DATA_DIR}/                  # Padrão: ../flumendata-data (irmão do repo FlumenData)
├── minio/                    # Armazenamento do MinIO (pode crescer em TBs)
│   ├── lakehouse/            # Tabelas Delta Lake
│   └── storage/              # Bucket de staging para arquivos brutos
└── notebooks/                # Notebooks do JupyterLab (SEU TRABALHO - coloque em versionamento!)
    ├── _examples/            # Notebooks somente leitura
    ├── 01_analysis.ipynb     # Seus notebooks
    └── .git/                 # Opcional: `git init` aqui
```

Todo o resto (metadados do PostgreSQL, logs do Spark, caches) fica em **volumes Docker** — você não precisa acessá-los diretamente.

## 🪟 Configuração Inicial (WSL + Windows)

### Passo 1: Crie o Diretório Base no Windows

**IMPORTANTE:** Em WSL, crie o diretório usando o Windows primeiro.

**Método 1 - Explorador (recomendado):**
1. `Win + E`
2. Vá até `Este Computador` → `D:`
3. Clique com o botão direito → `Novo` → `Pasta`
4. Nome: `data-projects`

**Método 2 - PowerShell:**
```powershell
New-Item -ItemType Directory -Path "D:\data-projects" -Force
```

**Método 3 - Prompt:**
```cmd
mkdir D:\data-projects
```

### Passo 2: Inicialize Diretórios de Dados

No WSL:
```bash
make init-data-dirs
```

Isso cria:
- `minio/lakehouse`
- `minio/storage`
- `notebooks/_examples`

### Passo 3: Finalize com `make init`

```bash
make init
```

Etapas executadas:
1. ✓ Verifica se os diretórios existem
2. ✓ Gera configurações
3. ✓ Sobe todos os serviços
4. ✓ Inicializa bancos/buckets

## ⚙️ Configuração

### Local dos Dados

**Padrão:** `DATA_DIR=../flumendata-data`

Estrutura recomendada:
```
workspace/
├── FlumenData/          # Repo git
└── flumendata-data/     # Seus dados
```

### Alterar Localização

Edite `.env` e ajuste `DATA_DIR`.

**Caminhos Relativos (recomendado):**
```bash
DATA_DIR=../flumendata-data   # Diretório irmão (padrão)
DATA_DIR=./data               # Dentro do projeto
DATA_DIR=../../meu-lakehouse  # Mais acima
```

**Caminhos Absolutos:**
```bash
DATA_DIR=/mnt/d/data-projects
DATA_DIR=/mnt/e/flumendata
DATA_DIR=/mnt/c/Users/SeuUsuario/flumendata
DATA_DIR=~/flumendata-data
DATA_DIR=/home/user/flumendata
DATA_DIR=/mnt/nas/flumendata
```

**Trade-offs:**
- **Relativo:** portátil, mais fácil para times
- **Absoluto:** explícito, útil para caminhos especiais

## 📓 Versione Seus Notebooks

O diretório `notebooks/` é perfeito para git!

```bash
cd /mnt/d/data-projects/notebooks
git init
git add .
git commit -m "Primeiro commit"
git remote add origin https://github.com/seuuser/flumendata-notebooks.git
git push -u origin main
```

### .gitignore recomendado

Crie `/mnt/d/data-projects/notebooks/.gitignore`:

```gitignore
.ipynb_checkpoints/
_examples/
__pycache__/
*.py[cod]
*.csv
*.parquet
*.xlsx
*.zip
```

## 💾 O que Fazer Backup

### Crítico

1. **MinIO** – `${DATA_DIR}/minio/`
   - Contém o lakehouse (tabelas Delta)
   - Pode atingir GBs/TBs

2. **Notebooks** – `${DATA_DIR}/notebooks/`
   - Seu trabalho analítico
   - Melhor solução: git

### Metadados (Volumes Docker)

- `flumen_postgres_data` – catálogo do Hive
- `flumen_superset_home` – dashboards
- `flumen_spark_logs` – logs (opcional)

### Comandos de Backup

```bash
# Compactar MinIO + Notebooks
 tar -czf flumendata-backup-$(date +%Y%m%d).tar.gz /mnt/d/data-projects

# Rsync para NAS
 rsync -av --progress /mnt/d/data-projects/ /mnt/nas/backups/flumendata/

# Ou apenas use git em notebooks
 cd /mnt/d/data-projects/notebooks
 git add . && git commit -m "Atualização" && git push
```

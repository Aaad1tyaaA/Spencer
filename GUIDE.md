# Spencer install guide

Spencer runs as four Docker containers: the app, Postgres (accounts), Redis (cache) and
Caddy (the web server). On your own machine **you set the limits**: as many workspaces as
you like, bigger uploads, more memory, unlimited AI with your own key.

- [1. What you need](#1-what-you-need)
- [2. Install](#2-install)
- [3. First sign-in and admin](#3-first-sign-in-and-admin)
- [4. Raise the limits](#4-raise-the-limits) (workspaces, upload size, storage, memory, AI)
- [5. Turn on AI](#5-turn-on-ai)
- [6. Update, back up, uninstall](#6-update-back-up-uninstall)
- [7. Put it on the internet](#7-put-it-on-the-internet)
- [Troubleshooting](#troubleshooting)

---

## 1. What you need

| | Minimum | Comfortable |
|---|---|---|
| Docker | [Docker Desktop](https://docs.docker.com/get-docker/) (Windows / macOS) or Docker Engine + Compose plugin (Linux) | same |
| Memory | 4 GB free | 8 GB+ (Spencer uses RAM to crunch big files) |
| Disk | 3 GB for Spencer + about 3× your data | an SSD |
| CPU | 2 cores, x86 or ARM (Apple Silicon, Raspberry Pi 5, cloud ARM VMs all work) | 4 cores |

On Windows, Docker Desktop needs WSL 2, which its installer sets up for you.

## 2. Install

**Start Docker Desktop**, then open a terminal and run one line:

```bash
# macOS / Linux
curl -fsSL https://raw.githubusercontent.com/Aaad1tyaaA/spencer/main/install.sh | sh
```

```powershell
# Windows (PowerShell)
irm https://raw.githubusercontent.com/Aaad1tyaaA/spencer/main/install.ps1 | iex
```

It downloads this kit into a `spencer` folder, creates a `.env` settings file with fresh
random secrets, downloads Spencer (about 1 GB the first time) and starts it. When it prints
**Spencer is running: http://localhost**, open that address.

Port 80 already in use? Choose another port:

```bash
curl -fsSL https://raw.githubusercontent.com/Aaad1tyaaA/spencer/main/install.sh | sh -s -- 8080
```

On Windows, download the kit (below) and run `.\setup.ps1 -Port 8080`. Then open http://localhost:8080.

<details>
<summary>Prefer not to pipe a script into your shell?</summary>

On GitHub choose **Code → Download ZIP**, unzip it, open a terminal in the folder and run
`./setup.sh` (macOS / Linux) or `powershell -ExecutionPolicy Bypass -File .\setup.ps1`
(Windows). Or entirely by hand:

```bash
cp .env.example .env     # then set SITE_ADDRESS=:80, SPENCER_FRONTEND_URL=http://localhost,
                         # the two secrets and POSTGRES_PASSWORD (openssl rand -hex 32)
docker compose pull
docker compose up -d
```
</details>

## 3. First sign-in and admin

Open the address and **Register**. Then, in the `spencer` folder, make yourself admin
(which adds Analytics and Storage pages to Settings):

```bash
docker compose exec backend python -m create_admin you@example.com
```

Sign out and back in. Without an email server (SMTP), new accounts are confirmed
immediately. To send confirmation and password-reset emails, fill the `SPENCER_SMTP_*`
settings in `.env` (any SMTP provider works: Brevo, Resend, Gmail app password, SES).

## 4. Raise the limits

Every limit is a line in `.env` (in the `spencer` folder). After editing it, apply with:

```bash
docker compose up -d
```

| What | Setting in `.env` | Default | Example |
|---|---|---|---|
| **Workspaces per account** | `SPENCER_MAX_WORKSPACES_PER_USER` | `3` | `20`, or `0` for unlimited |
| **Largest file you can upload** | `SPENCER_MAX_UPLOAD_MB` **and** `MAX_REQUEST_BODY` | `100` and `110MB` | `2000` and `2010MB` for 2 GB files |
| **Memory for crunching data** | `SPENCER_DUCKDB_MEMORY_LIMIT` | `4GB` | about a third of your RAM, e.g. `10GB` on 32 GB |
| **Memory cap for the app container** | `BACKEND_MEM_LIMIT` | `7g` | a bit more than the line above, e.g. `14g` |
| **Shared AI prompts per user per day** | `SPENCER_AI_PROMPTS_PER_DAY` | `5` | `100`, or `0` for no daily limit |
| **AI requests per user per minute** | `SPENCER_AI_REQUESTS_PER_MINUTE` | `20` | `60`, or `0` for no limit |
| **Delete idle workspaces after N days** | `SPENCER_OWNED_RETENTION_DAYS` | `0` (keep forever) | `90` |
| **Largest saved dashboard** (images included) | `SPENCER_DASHBOARD_MAX_BYTES` | `8388608` (8 MB) | `33554432` (32 MB) |
| **Query history kept per workspace** | `SPENCER_QUERY_HISTORY_CAP` | `30` | `200` |
| **Sign-in session length (hours)** | `SPENCER_JWT_EXPIRY_HOURS` | `24` | `168` (a week) |
| **Allowed upload types** | `SPENCER_UPLOAD_ALLOWED_EXT` | `csv,tsv,parquet,json,xlsx` | remove types you don't want |
| **Who can sign up** | `SPENCER_ALLOW_REGISTRATION` | `true` from the setup script | `false` once your team is in |

**Why two settings for upload size?** `SPENCER_MAX_UPLOAD_MB` is Spencer's own check (and
what the upload box shows); `MAX_REQUEST_BODY` is the web server's cap in front of it.
Keep the second slightly larger, or big uploads stop at the web server.

**Big files need memory.** Joins and group-bys over multi-GB files are much faster with a
larger `SPENCER_DUCKDB_MEMORY_LIMIT`. Raise `BACKEND_MEM_LIMIT` with it, and keep both
below the memory Docker may use (Docker Desktop → Settings → Resources on Windows / macOS).

### Storage: where your data lives, and giving it more space

All data is in Docker volumes, so it survives restarts and updates:

| Volume | Holds |
|---|---|
| `spencer_backend_data` | uploaded files, the analytics database, backups |
| `spencer_pg_data` | accounts, workspaces, dashboards, settings |
| `spencer_redis_data` | caches only (safe to lose) |

See how much they use with `docker system df -v`. To give Spencer more room:

- **Docker Desktop (Windows / macOS):** Settings → Resources → Advanced → *Disk image
  location / size*. Move it to a bigger drive or raise the size.
- **Linux:** volumes live under `/var/lib/docker/volumes`. Move Docker's data root to a
  bigger disk (`"data-root"` in `/etc/docker/daemon.json`), or mount a bigger disk there.

Admins also get a Storage page in Settings that shows Spencer's footprint and can clear
expired data on demand.

## 5. Turn on AI

Two options, and you can use both:

- **Your own key, per user (easiest):** each person opens **Settings → AI & Intelligence →
  Your own API key**, picks a provider (Gemini, Anthropic, OpenAI, OpenRouter, DeepSeek,
  Mistral, Groq and 14 more) and pastes a key. **Auto** picks a model the key can use. No
  daily limit from Spencer applies; the provider bills that person.
- **A server key for everyone:** put a key in `.env`, e.g. `GEMINI_API_KEY=...` (or
  `ANTHROPIC_API_KEY`; several comma-separated in `GEMINI_API_KEYS` rotate), optionally
  `SPENCER_LLM_MODEL=gemini/gemini-3.6-flash`, then `docker compose up -d`. Everyone shares
  it within `SPENCER_AI_PROMPTS_PER_DAY`.

## 6. Update, back up, uninstall

**Update to the latest version** (your data is kept; database changes apply on start). In
the `spencer` folder:

```bash
docker compose pull
docker compose up -d
```

To stay on a specific release instead, set `SPENCER_VERSION=1.2.0` in `.env`.

**Backups:** the analytics database is copied every 24 hours and the last 7 copies are
kept (`SPENCER_BACKUP_INTERVAL_HOURS`, `SPENCER_BACKUP_KEEP`), inside the data volume. They
live on the same disk, so copy them elsewhere now and then. For accounts and dashboards:

```bash
docker compose exec -T db pg_dump -U spencer spencer > spencer-accounts.sql
```

**Stop** with `docker compose down` (data kept). **Remove everything, including all data**,
with `docker compose down -v`. There is no undo for that one.

## 7. Put it on the internet

On a server with a public IP (any cloud VM with Docker):

1. Open ports **80** and **443** in the server's firewall.
2. In `.env`, set `SITE_ADDRESS` to your domain, e.g. `SITE_ADDRESS=bi.example.com` (point
   its DNS A record at the server). No domain? Use the free name for your IP:
   `SITE_ADDRESS=129-146-10-20.sslip.io` for IP 129.146.10.20.
3. Set `SPENCER_FRONTEND_URL=https://` + that same address.
4. `docker compose up -d`. Caddy gets a free HTTPS certificate on its own within a minute.

Then set `SPENCER_ALLOW_REGISTRATION=false` once your team has accounts, and fill the
`SPENCER_SMTP_*` settings so password resets work.

## Troubleshooting

| Problem | Fix |
|---|---|
| `port is already allocated` for 80 or 443 | Set `HTTP_PORT=8080` and `HTTPS_PORT=8443` in `.env`, then `docker compose up -d` |
| The page doesn't load | `docker compose ps` (all four should be running) and `docker compose logs backend` |
| "Refusing to start: ... JWT secret" | A secret in `.env` is still a placeholder: fill it (`openssl rand -hex 32`) |
| `docker compose pull` says *denied* or *not found* | Check your internet connection, then try again; if it persists, report it on the GitHub page |
| Uploads stop at a size | Raise **both** `SPENCER_MAX_UPLOAD_MB` and `MAX_REQUEST_BODY` |
| The app keeps restarting with big files | It ran out of memory: raise `BACKEND_MEM_LIMIT` (and Docker Desktop's memory), or lower `SPENCER_DUCKDB_MEMORY_LIMIT` |

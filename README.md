# Spencer: install on your own computer or server

Spencer is a self-contained BI tool: upload a spreadsheet or database export, clean it,
connect tables, build Power BI-style dashboards, and ask questions in plain English that
become SQL you review before it runs.

This repository is the **install kit**: it runs Spencer's ready-made Docker images on
your machine. Your data stays on your machine, and you choose the limits (workspaces,
upload size, memory, AI). Try it online first at **https://spencer-bi-engine.vercel.app**.

## Install

Start [Docker Desktop](https://docs.docker.com/get-docker/) (or Docker Engine on Linux),
then run one line:

```bash
# macOS / Linux
curl -fsSL https://raw.githubusercontent.com/Aaad1tyaaA/spencer/main/install.sh | sh
```

```powershell
# Windows (PowerShell)
irm https://raw.githubusercontent.com/Aaad1tyaaA/spencer/main/install.ps1 | iex
```

When it prints **Spencer is running**, open **http://localhost** and create your account.

## Next

- [GUIDE.md](GUIDE.md): make yourself admin, **raise the limits** (unlimited workspaces,
  multi-GB uploads, more memory and storage), turn on AI, update, back up, and put it on
  the internet with HTTPS.
- Update any time: `docker compose pull && docker compose up -d` in the `spencer` folder.

## What's in this kit

| File | Purpose |
|---|---|
| `install.sh`, `install.ps1` | One-line installers: download this kit and run the setup |
| `setup.sh`, `setup.ps1` | Create `.env` with random secrets, download and start Spencer |
| `docker-compose.yml` | The four containers (app, Postgres, Redis, Caddy web server) |
| `Caddyfile` | Web server settings (HTTPS, security headers) |
| `.env.example` | Every setting, with explanations |
| `GUIDE.md` | The full guide |

## License

Free to download and run, for personal and business use, under the
[Spencer Free Use License](LICENSE). Spencer's source code is not published.

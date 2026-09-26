#!/usr/bin/env sh
# Spencer one-line installer (macOS / Linux):
#   curl -fsSL https://raw.githubusercontent.com/Aaad1tyaaA/spencer/main/install.sh | sh
# Downloads the install kit into ./spencer and runs its setup (Docker required).
# Pass a port for the local address:  curl -fsSL https://raw.githubusercontent.com/Aaad1tyaaA/spencer/main/install.sh | sh -s -- 8080
set -eu
DIR="${SPENCER_DIR:-spencer}"
mkdir -p "$DIR"
cd "$DIR"
for f in docker-compose.yml Caddyfile .env.example setup.sh setup.ps1 GUIDE.md LICENSE; do
  curl -fsSL "https://raw.githubusercontent.com/Aaad1tyaaA/spencer/main/$f" -o "$f"
done
chmod +x setup.sh
echo "Install kit downloaded to $(pwd)"
exec ./setup.sh "$@"

#!/usr/bin/env sh
# Spencer: one-command local install (macOS / Linux). Needs Docker with the Compose plugin.
#
#   ./setup.sh            # serves http://localhost
#   ./setup.sh 8080       # serves http://localhost:8080 (when port 80 is taken)
#
# Creates .env (only if it doesn't exist yet) with fresh random secrets and local settings,
# then downloads and starts Spencer. Safe to run again: an existing .env is kept.
set -eu
cd "$(dirname "$0")"

PORT="${1:-80}"
case "$PORT" in *[!0-9]*|'') echo "Port must be a number, e.g. 8080"; exit 1 ;; esac

if ! docker compose version >/dev/null 2>&1; then
  echo "Docker with the Compose plugin is required: https://docs.docker.com/get-docker/"
  exit 1
fi

rand() {
  if command -v openssl >/dev/null 2>&1; then openssl rand -hex "$1"
  else head -c "$1" /dev/urandom | od -An -tx1 | tr -d ' \n'; fi
}

if [ -f .env ]; then
  echo "Keeping your existing .env"
else
  URL="http://localhost"
  [ "$PORT" = "80" ] || URL="http://localhost:$PORT"
  awk -v jwt="$(rand 32)" -v enc="$(rand 32)" -v pg="$(rand 24)" -v url="$URL" '
    /^SITE_ADDRESS=/                  { print "SITE_ADDRESS=:80"; next }
    /^SPENCER_JWT_SECRET=/            { print "SPENCER_JWT_SECRET=" jwt; next }
    /^SPENCER_KEY_ENCRYPTION_SECRET=/ { print "SPENCER_KEY_ENCRYPTION_SECRET=" enc; next }
    /^POSTGRES_PASSWORD=/             { print "POSTGRES_PASSWORD=" pg; next }
    /^SPENCER_FRONTEND_URL=/          { print "SPENCER_FRONTEND_URL=" url; next }
    /^SPENCER_ALLOW_REGISTRATION=/    { print "SPENCER_ALLOW_REGISTRATION=true"; next }
    /^SPENCER_STRICT_SIGNUP_EMAIL=/   { print "SPENCER_STRICT_SIGNUP_EMAIL=false"; next }
    { print }
  ' .env.example > .env
  [ "$PORT" = "80" ] || printf '\n# Local install on a custom port\nHTTP_PORT=%s\nHTTPS_PORT=%s\n' "$PORT" "$((PORT + 363))" >> .env
  echo "Created .env with new random secrets"
fi

echo "Downloading and starting Spencer (the first download is about 1 GB)..."
docker compose pull
docker compose up -d

URL="$(sed -n 's/^SPENCER_FRONTEND_URL=//p' .env)"
printf "Waiting for Spencer to be ready"
i=0
while [ $i -lt 90 ]; do
  if curl -fsS "$URL/health" >/dev/null 2>&1; then
    printf "\n\nSpencer is running: %s\nCreate an account there, then make it admin with:\n  docker compose exec backend python -m create_admin you@example.com\n" "$URL"
    exit 0
  fi
  printf "."; sleep 2; i=$((i + 1))
done
printf "\nSpencer didn't answer yet. Check: docker compose ps  and  docker compose logs backend\n"
exit 1

#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

need() { command -v "$1" >/dev/null || { echo "Missing: $1" >&2; exit 1; }; }
need docker
need openssl
docker compose version >/dev/null

if [[ ! -f .env ]]; then
  cp .env.example .env
fi

if grep -q 'DOMAIN=http://192.168.1.50:8081' .env; then
  IP="$(hostname -I 2>/dev/null | awk '{print $1}' || true)"
  PORT="$(grep -E '^PORT=' .env | cut -d= -f2 || echo 8081)"
  if [[ -n "${IP}" ]]; then
    sed -i "s|^DOMAIN=.*|DOMAIN=http://${IP}:${PORT}|" .env
    echo "Set DOMAIN=http://${IP}:${PORT} in .env (edit if wrong)."
  fi
fi

if grep -q 'ADMIN_TOKEN=CHANGE_ME' .env; then
  TOKEN="$(openssl rand -base64 48 | tr -d '\n')"
  sed -i "s|^ADMIN_TOKEN=.*|ADMIN_TOKEN=${TOKEN}|" .env
  umask 077
  printf '%s\n' "${TOKEN}" > .admin-token
  echo "Generated ADMIN_TOKEN (also saved to .admin-token)."
fi

mkdir -p data
docker compose pull
docker compose up -d

DOMAIN_VAL="$(grep -E '^DOMAIN=' .env | cut -d= -f2-)"
cat <<MSG

Vaultwarden is starting.

URL:   ${DOMAIN_VAL}
Admin: ${DOMAIN_VAL}/admin  (token in .admin-token)

1) Create your account in the browser
2) Then disable public signups:

   sed -i 's/^SIGNUPS_ALLOWED=.*/SIGNUPS_ALLOWED=false/' .env
   docker compose up -d

MSG

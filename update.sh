#!/usr/bin/env bash
# Safely update the running Vaultwarden stack and remove dangling images.
# Safe to run while containers are up (Compose recreates only what changed).
# Does NOT regenerate ADMIN_TOKEN or wipe data/.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

need() { command -v "$1" >/dev/null || { echo "Missing: $1" >&2; exit 1; }; }
need docker
docker compose version >/dev/null

if [[ ! -f .env ]]; then
  echo "No .env found. Run ./install.sh first." >&2
  exit 1
fi

echo "==> Pulling newer images..."
docker compose pull
echo "==> Recreating containers if images/config changed (brief downtime)..."
docker compose up -d --remove-orphans
echo "==> Status:"
docker compose ps
echo "==> Removing dangling (untagged) images only — not other projects' images..."
docker image prune -f

echo
echo "Update finished. Vaultwarden data/ and ADMIN_TOKEN were left untouched."

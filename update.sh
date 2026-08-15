#!/usr/bin/env bash
# Safely update the running Vaultwarden stack and remove dangling images.
# Creates a local rollback backup first, then asks whether to keep it.
# Does NOT regenerate ADMIN_TOKEN.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

need() { command -v "$1" >/dev/null || { echo "Missing: $1" >&2; exit 1; }; }

ask_backup_retention() {
  local dir="$1"
  if [[ ! -d "${dir}" ]]; then
    return 0
  fi
  if [[ ! -t 0 ]]; then
    echo "No interactive terminal — keeping backup at ${dir}"
    return 0
  fi
  echo
  local reply=""
  read -r -p "Update succeeded. Keep rollback backup at ${dir}? [Y/n] " reply || true
  case "${reply:-Y}" in
    n|N|no|NO)
      rm -rf "${dir}"
      rmdir backups 2>/dev/null || true
      echo "Backup deleted."
      ;;
    *)
      echo "Backup kept."
      echo "  See ${dir}/RESTORE.txt if you need to roll back."
      ;;
  esac
}

create_backup() {
  BACKUP_DIR="backups/update-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "${BACKUP_DIR}"
  echo "==> Creating rollback backup in ${BACKUP_DIR} ..."
  [[ -f .env ]] && cp -a .env "${BACKUP_DIR}/"
  [[ -f .admin-token ]] && cp -a .admin-token "${BACKUP_DIR}/"
  [[ -f docker-compose.yml ]] && cp -a docker-compose.yml "${BACKUP_DIR}/"
  if [[ -d data ]]; then
    tar -C data -czf "${BACKUP_DIR}/data.tar.gz" .
  fi
  cat >"${BACKUP_DIR}/RESTORE.txt" <<EOF
Vaultwarden Docker rollback:

  cd $(pwd)
  docker compose down
  cp -a ${BACKUP_DIR}/.env .env
  cp -a ${BACKUP_DIR}/.admin-token .admin-token 2>/dev/null || true
  rm -rf data
  mkdir -p data
  tar -C data -xzf ${BACKUP_DIR}/data.tar.gz
  docker compose up -d
EOF
  echo "Backup ready: ${BACKUP_DIR}"
}

need docker
docker compose version >/dev/null

if [[ ! -f .env ]]; then
  echo "No .env found. Run ./install.sh first." >&2
  exit 1
fi

create_backup

echo "==> Pulling newer images..."
docker compose pull
echo "==> Recreating containers if images/config changed (brief downtime)..."
docker compose up -d --remove-orphans
echo "==> Status:"
docker compose ps
echo "==> Removing dangling (untagged) images only — not other projects' images..."
docker image prune -f

echo
echo "Update finished. Live data/ was left in place (backup is a point-in-time copy)."
ask_backup_retention "${BACKUP_DIR}"

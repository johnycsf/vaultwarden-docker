#!/usr/bin/env bash
# Safely update the running Vaultwarden stack and remove dangling images.
# Creates a local rollback backup first, then asks whether to keep it.
# Does NOT regenerate ADMIN_TOKEN.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

KEEP_FILE=".backup-keep-count"
DEFAULT_KEEP=3

print_offsite_tip() {
  cat <<'EOF'

Tip: Local backups under backups/ can fill your disk over time.
Copy important snapshots to an external drive, NAS, or cloud
(rclone, Backblaze B2, S3, Nextcloud, etc.), then keep fewer copies here.
Restore later with: ./restore.sh
EOF
}

prune_old_backups() {
  local keep="$1"
  mkdir -p backups
  mapfile -t dirs < <(ls -1dt backups/update-* 2>/dev/null || true)
  local total="${#dirs[@]}"
  if (( total <= keep )); then
    echo "Backup retention: keeping all ${total} local snapshot(s) (limit ${keep})."
    return 0
  fi
  local i
  for (( i = keep; i < total; i++ )); do
    echo "Removing old backup: ${dirs[$i]}"
    rm -rf "${dirs[$i]}"
  done
  echo "Backup retention: kept ${keep} newest snapshot(s); removed $((total - keep)) older one(s)."
}

ask_backup_retention() {
  local dir="$1"
  if [[ ! -d "${dir}" ]]; then
    return 0
  fi
  if [[ ! -t 0 ]]; then
    echo "No interactive terminal — keeping backup at ${dir}"
    local keep="${DEFAULT_KEEP}"
    [[ -f "${KEEP_FILE}" ]] && keep="$(tr -dc '0-9' <"${KEEP_FILE}" || true)"
    [[ -z "${keep}" ]] && keep="${DEFAULT_KEEP}"
    echo "${keep}" >"${KEEP_FILE}"
    prune_old_backups "${keep}"
    print_offsite_tip
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
      local default="${DEFAULT_KEEP}"
      [[ -f "${KEEP_FILE}" ]] && default="$(tr -dc '0-9' <"${KEEP_FILE}" || true)"
      [[ -z "${default}" ]] && default="${DEFAULT_KEEP}"
      local keep=""
      read -r -p "How many local update backups should we keep on this disk? [${default}] " keep || true
      keep="$(printf '%s' "${keep:-$default}" | tr -dc '0-9')"
      [[ -z "${keep}" || "${keep}" -lt 1 ]] && keep="${default}"
      echo "${keep}" >"${KEEP_FILE}"
      prune_old_backups "${keep}"
      print_offsite_tip
      echo "  This snapshot: ${dir}"
      echo "  Manual restore: ./restore.sh"
      ;;
  esac
}


need() { command -v "$1" >/dev/null || { echo "Missing: $1" >&2; exit 1; }; }


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
Prefer: ./restore.sh

Manual Vaultwarden Docker rollback:

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

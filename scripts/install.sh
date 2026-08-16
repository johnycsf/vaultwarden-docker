#!/usr/bin/env bash
# Install Vaultwarden with Docker Compose (interactive).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
# shellcheck source=scripts/deps.sh
source "${ROOT}/scripts/deps.sh"

ui_banner "Vaultwarden" "Docker Compose · official vaultwarden/server image"
ui_steps_init 4

ui_step "Checking host dependencies"
ensure_host_deps docker sqlite3

ui_step "Preparing configuration"
if [[ ! -f .env ]]; then
  cp .env.example .env
  ui_ok "Created .env from .env.example"
else
  ui_ok "Using existing .env"
fi

configure_host_port PORT "Vaultwarden HTTP" 8081
IP="$(hostname -I 2>/dev/null | awk '{print $1}' || true)"
if [[ -n "${IP}" ]]; then
  env_file_set DOMAIN "http://${IP}:${PORT}"
  ui_ok "DOMAIN=http://${IP}:${PORT}"
elif grep -q 'DOMAIN=http://192.168.1.50:8081' .env; then
  ui_warn "Could not detect IP — edit DOMAIN in .env"
fi

if grep -q 'ADMIN_TOKEN=CHANGE_ME' .env; then
  TOKEN="$(openssl rand -base64 48 | tr -d '\n')"
  sed -i "s|^ADMIN_TOKEN=.*|ADMIN_TOKEN=${TOKEN}|" .env
  umask 077
  printf '%s\n' "${TOKEN}" > .admin-token
  ui_ok "Generated ADMIN_TOKEN (saved to .admin-token)"
else
  ui_ok "ADMIN_TOKEN already set — leaving it alone"
fi

mkdir -p data

ui_step "Pulling images"
ui_run "docker compose pull" docker compose pull

ui_step "Starting Vaultwarden"
ui_run "docker compose up -d" docker compose up -d

DOMAIN_VAL="$(grep -E '^DOMAIN=' .env | cut -d= -f2-)"
echo
ui_ok "Vaultwarden is starting"
ui_info "URL:   ${UI_BOLD}${DOMAIN_VAL}${UI_RESET}"
ui_info "Admin: ${UI_BOLD}${DOMAIN_VAL}/admin${UI_RESET}  (token in .admin-token)"
echo
ui_info "1) Create your account in the browser"
ui_info "2) Then disable public signups:"
echo "     sed -i 's/^SIGNUPS_ALLOWED=.*/SIGNUPS_ALLOWED=false/' .env && docker compose up -d"

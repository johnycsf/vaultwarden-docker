# vaultwarden-docker

![Repobeats analytics image](https://repobeats.axiom.co/api/embed/6781d12a788abf6f1b29a66135462189dfd91901.svg "Repobeats analytics image")

[![Sponsor](https://img.shields.io/badge/Sponsor-%E2%9D%A4-ea4aaa?logo=githubsponsors&logoColor=white)](https://github.com/sponsors/johnycsf)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Issues](https://img.shields.io/badge/issues-welcome-lightgrey.svg)](../../issues/new/choose)

Deploy [Vaultwarden](https://github.com/dani-garcia/vaultwarden) (Bitwarden-compatible password manager) with Docker Compose.

Kubernetes version: [vaultwarden-k8s](https://github.com/johnycsf/vaultwarden-k8s)

Follows Vaultwarden guidance using the **official** project image [`vaultwarden/server`](https://hub.docker.com/r/vaultwarden/server): set `DOMAIN`, keep signups open only long enough to create your first account, store `ADMIN_TOKEN` outside git.

**One-command Vaultwarden** — official `vaultwarden/server`, interactive install, safe updates & backups.

> **Choose your path:** **Docker Compose (this repo)** · [Kubernetes](https://github.com/johnycsf/vaultwarden-k8s)

## Who this is for

**Good fit:** a personal or family password manager on a trusted LAN / reverse proxy.

**Not for:** replacing Bitwarden’s official commercial cloud — Vaultwarden is unofficial and compatible; you own ops and backups.

## Why this repo (not just another compose file)

- **`./manage.sh`** control center — install, update, backup, status/doctor, uninstall
- Interactive colored install with step progress
- Auto-detects your OS and installs missing host tools
- Safe **`./manage.sh update`** with automatic pre-update backup
- Incremental hardlink **`./manage.sh backup`** + restore
- **Official upstream images only**

## Support this work

If this stack saved you setup time, please consider sponsoring — it funds:

- Keeping install/update/backup scripts working across common Linux distros
- Testing safe upgrades against **official** upstream images
- Building more beginner-friendly stacks that share the same `./manage.sh` UX

[![Sponsor johnycsf](https://img.shields.io/badge/GitHub%20Sponsors-Donate-ea4aaa?logo=githubsponsors&logoColor=white)](https://github.com/sponsors/johnycsf)

👉 **[github.com/sponsors/johnycsf](https://github.com/sponsors/johnycsf)**

## What you need

- A Linux host (Debian/Ubuntu, Fedora/RHEL, Arch, openSUSE, Alpine) or macOS with Homebrew
- `sudo` so `./manage.sh` can install missing tools (Docker, curl, openssl, rsync, …)
- Enough disk for your data

`./manage.sh` is interactive (colors + step progress), detects your OS, and installs host dependencies automatically.

## Install

```bash
git clone https://github.com/johnycsf/vaultwarden-docker.git
cd vaultwarden-docker
chmod +x manage.sh
./manage.sh          # interactive control center
# or: ./manage.sh
```

Open the URL printed by the script, create your account, then disable signups as instructed.

Liked the install? Star the repo or [sponsor johnycsf](https://github.com/sponsors/johnycsf) so more stacks stay maintained.

## Customize

Edit `.env` (created from `.env.example`):

| Variable | Purpose |
|----------|---------|
| `DOMAIN` | Full public URL users will use |
| `PORT` | Host port (default `8081`) |
| `SIGNUPS_ALLOWED` | `true` initially, then `false` |
| `ADMIN_TOKEN` | Admin page password (auto-generated) |

## Update

Keep the stack current (safe while running; brief recreate downtime):

```bash
./manage.sh update
```

Before changing anything, the script runs `./manage.sh backup` into `./backups` (incremental, database-safe). After a successful update it asks whether to **keep** or **delete** that snapshot, and how many local copies to retain (older ones are pruned). Copy important backups to an external drive, NAS, or cloud so they do not fill this disk.

To roll back later (same tool as disaster recovery):

```bash
./manage.sh backup --restore --from ./backups
# or from an external copy:
./manage.sh backup --restore --from /mnt/usb/my-backups
```

Older `backups/update-*` tarball folders (from previous script versions) are no longer used by `./manage.sh update`; use each folder's `RESTORE.txt` if you still need one, or delete them to free space.

This pulls/rebuilds images, recreates containers as needed, and runs `docker image prune` for **dangling** (untagged) images only — it will not wipe other projects' images or your `data/` volume.

## Disaster recovery (full backup / restore)

Incremental snapshots via `rsync` hardlinks (unchanged files are not re-copied). `./manage.sh update` uses this same `backup.sh` before updating (into `./backups`).

```bash
# Backup to USB/NAS/external path (repeat anytime; later runs are incremental)
./manage.sh backup --dest /mnt/usb/vaultwarden-docker-backups
./manage.sh backup --dest /mnt/usb/vaultwarden-docker-backups --keep 5   # optional: retain only newest N

# On a brand-new machine/cluster after ./manage.sh:
./manage.sh backup --restore --from /mnt/usb/vaultwarden-docker-backups
# or a specific snapshot:
./manage.sh backup --restore --from /mnt/usb/vaultwarden-docker-backups/snapshots/YYYYMMDD-HHMMSS
```

Each snapshot includes `SHA256SUMS` plus a `snapshot_sha256` key in `META.txt`. Restore verifies these and **warns** (does not abort) if integrity is lost.

Keep the backup root on **one filesystem** so hardlinks work. Prefer an external drive, NAS, or cloud sync of that folder.

**Database safety:** Nextcloud uses a verified MariaDB *logical* dump (`mariadb-dump --single-transaction`) — the live `data/db` / DB PVC files are never rsync'd. SQLite apps (Heimdall, Vaultwarden) are stopped or scaled to 0, WAL-checkpointed when `sqlite3` is available, integrity-checked, then copied. Incremental hardlinks apply to file trees; each SQL dump is a full verified file with a SHA-256 in `META.txt`.

## Uninstall

```bash
docker compose down
rm -rf data .env .admin-token
```

## Credits

This repo packages or configures upstream software. See [CREDITS.md](CREDITS.md) for the main developers and projects this work builds on.

## Disclaimer

This project is provided **as is**. The author is **not responsible** for any loss, damage, data corruption, downtime, security issues, or other consequences from using it. Full text: [DISCLAIMER.md](DISCLAIMER.md).

## Bug reports & contributions

If you hit an error, please [open a GitHub Issue](../../issues/new/choose) and follow [CONTRIBUTING.md](CONTRIBUTING.md). Fixes via Pull Request are welcome. GitHub Issues/PRs are the supported way to report problems—there is no private support channel.

## Interactive control center

`./manage.sh` opens a simple **↑/↓ menu** with a `>` cursor (j/k and Enter also work). No extra packages required.

## Host ports

During `./manage.sh` (or Manage → Install / reconfigure), the script checks whether default host ports are free, lets you keep the defaults or choose different ports, and saves them in `.env`. Re-running install keeps your current ports unless you change them.

Non-interactive: set the port variables in `.env` (or the environment) and use `SKIP_PORT_PROMPTS=1`.

## Container engine

During `./manage.sh` → Install you can choose **Docker** or **Podman**. The choice is saved as `CONTAINER_ENGINE` in `.env`. All manage actions (`update`, `backup`, `restore`, …) use that engine via a shared `compose` helper.

## Backup exports

> **Note:** After containers start, some files under `data/` may be root-owned. Install/restore automatically fixes ownership for the invoking user so host-side `rsync` backup/restore does not fail with permission errors.

Local snapshots stay as incremental hardlink trees (fast rollback). Optionally create a compressed offsite copy with `./manage.sh backup --dest ./backups --archive tar.gz|tar.xz|zip` (add `--archive-password` for zip password or age-passphrase on tar). For stronger key-based encryption use `--encrypt` (age). See repo-framework `docs/BACKUP_ENCRYPTION.md`.

## Security

See [SECURITY.md](SECURITY.md) for how to report vulnerabilities.

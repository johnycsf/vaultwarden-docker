# vaultwarden-docker

![Repobeats analytics image](https://repobeats.axiom.co/api/embed/6781d12a788abf6f1b29a66135462189dfd91901.svg "Repobeats analytics image")


[![Sponsor](https://img.shields.io/badge/Sponsor-%E2%9D%A4-ea4aaa?logo=githubsponsors&logoColor=white)](https://github.com/sponsors/johnycsf)

Deploy [Vaultwarden](https://github.com/dani-garcia/vaultwarden) (Bitwarden-compatible password manager) with Docker Compose.

Kubernetes version: [vaultwarden-k8s](https://github.com/johnycsf/vaultwarden-k8s)

Follows Vaultwarden guidance using the **official** project image [`vaultwarden/server`](https://hub.docker.com/r/vaultwarden/server): set `DOMAIN`, keep signups open only long enough to create your first account, store `ADMIN_TOKEN` outside git.


## Why this repo (not just another compose file)

- **`./manage.sh`** control center — install, update, backup, status/doctor, uninstall
- Interactive colored install with step progress
- Auto-detects your OS and installs missing host tools
- Safe **`./update.sh`** with automatic pre-update backup
- Incremental hardlink **`./backup.sh`** + restore
- **Official upstream images only**

## What you need

- A Linux host (Debian/Ubuntu, Fedora/RHEL, Arch, openSUSE, Alpine) or macOS with Homebrew
- `sudo` so `./install.sh` can install missing tools (Docker, curl, openssl, rsync, …)
- Enough disk for your data

`./install.sh` is interactive (colors + step progress), detects your OS, and installs host dependencies automatically.

## Install

```bash
git clone https://github.com/johnycsf/vaultwarden-docker.git
cd vaultwarden-docker
chmod +x manage.sh install.sh
./manage.sh          # interactive control center
# or: ./install.sh
```

Open the URL printed by the script, create your account, then disable signups as instructed.

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
chmod +x update.sh
./update.sh
```

Before changing anything, the script runs `./backup.sh` into `./backups` (incremental, database-safe). After a successful update it asks whether to **keep** or **delete** that snapshot, and how many local copies to retain (older ones are pruned). Copy important backups to an external drive, NAS, or cloud so they do not fill this disk.

To roll back later (same tool as disaster recovery):

```bash
./backup.sh --restore --from ./backups
# or from an external copy:
./backup.sh --restore --from /mnt/usb/my-backups
```

Older `backups/update-*` tarball folders (from previous script versions) are no longer used by `./update.sh`; use each folder's `RESTORE.txt` if you still need one, or delete them to free space.

This pulls/rebuilds images, recreates containers as needed, and runs `docker image prune` for **dangling** (untagged) images only — it will not wipe other projects' images or your `data/` volume.



## Disaster recovery (full backup / restore)

Incremental snapshots via `rsync` hardlinks (unchanged files are not re-copied). `./update.sh` uses this same `backup.sh` before updating (into `./backups`).

```bash
chmod +x backup.sh

# Backup to USB/NAS/external path (repeat anytime; later runs are incremental)
./backup.sh --dest /mnt/usb/vaultwarden-docker-backups
./backup.sh --dest /mnt/usb/vaultwarden-docker-backups --keep 5   # optional: retain only newest N

# On a brand-new machine/cluster after ./install.sh:
./backup.sh --restore --from /mnt/usb/vaultwarden-docker-backups
# or a specific snapshot:
./backup.sh --restore --from /mnt/usb/vaultwarden-docker-backups/snapshots/YYYYMMDD-HHMMSS
```

Each snapshot includes `SHA256SUMS` plus a `snapshot_sha256` key in `META.txt`. Restore verifies these and **warns** (does not abort) if integrity is lost.

Keep the backup root on **one filesystem** so hardlinks work. Prefer an external drive, NAS, or cloud sync of that folder.

**Database safety:** Nextcloud uses a verified MariaDB *logical* dump (`mariadb-dump --single-transaction`) — the live `data/db` / DB PVC files are never rsync'd. SQLite apps (Heimdall, Vaultwarden) are stopped or scaled to 0, WAL-checkpointed when `sqlite3` is available, integrity-checked, then copied. Incremental hardlinks apply to file trees; each SQL dump is a full verified file with a SHA-256 in `META.txt`.


## Uninstall

```bash
docker compose down
rm -rf data .env .admin-token
```


## Disclaimer

This project is provided **as is**. The author is **not responsible** for any loss, damage, data corruption, downtime, security issues, or other consequences from using it. Full text: [DISCLAIMER.md](DISCLAIMER.md).

## Bug reports & contributions

If you hit an error, please [open a GitHub Issue](../../issues/new/choose) and follow [CONTRIBUTING.md](CONTRIBUTING.md). Fixes via Pull Request are welcome. GitHub Issues/PRs are the supported way to report problems—there is no private support channel.

## Support this work

If these homelab tools save you time, please consider sponsoring:

[![Sponsor johnycsf](https://img.shields.io/badge/GitHub%20Sponsors-Donate-ea4aaa?logo=githubsponsors&logoColor=white)](https://github.com/sponsors/johnycsf)

👉 **[github.com/sponsors/johnycsf](https://github.com/sponsors/johnycsf)** — tips and monthly support keep these beginner-friendly stacks maintained.


# vaultwarden-docker

Deploy [Vaultwarden](https://github.com/dani-garcia/vaultwarden) (Bitwarden-compatible password manager) with Docker Compose.

Kubernetes version: [vaultwarden-k8s](https://github.com/johnycsf/vaultwarden-k8s)

Follows Vaultwarden guidance using the **official** project image [`vaultwarden/server`](https://hub.docker.com/r/vaultwarden/server): set `DOMAIN`, keep signups open only long enough to create your first account, store `ADMIN_TOKEN` outside git.

## What you need

- Docker with Compose plugin
- `openssl` (used by `install.sh` to generate the admin token)

## Install

```bash
git clone https://github.com/johnycsf/vaultwarden-docker.git
cd vaultwarden-docker
chmod +x install.sh
./install.sh
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

```bash
docker compose pull
docker compose up -d
```

## Uninstall

```bash
docker compose down
rm -rf data .env .admin-token
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

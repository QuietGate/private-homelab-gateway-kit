# Quick Start

This guide assumes you are using Ubuntu, Debian, a Proxmox VM, or a Proxmox LXC with Docker already installed.

## What this guide sets up

This guide starts the core QuietGate stack:

- Traefik reverse proxy
- Homepage dashboard
- Uptime Kuma private monitoring
- Whoami routing test app
- Tailscale-only access
- no public router ports

## Before you start

Check that:

- Docker is installed
- Docker Compose works with `docker compose`
- Tailscale is installed on the host server
- the server is connected to your Tailscale network
- your terminal account can run Docker commands
- no router port forwarding is required for this stack

Useful checks:

    docker compose version
    tailscale status
    tailscale ip -4

## 1. Copy the environment file

Run:

    cp .env.example .env

## 2. Find your Tailscale IP

Run:

    tailscale ip -4

The result should be your server's Tailscale IPv4 address.

## 3. Edit .env

Open `.env`:

    nano .env

Set these values:

    TAILSCALE_IP=100.x.x.x
    BASE_DOMAIN=100.x.x.x.nip.io
    HOMEPAGE_ALLOWED_HOSTS=homepage.100.x.x.x.nip.io

Replace every `100.x.x.x` with your own Tailscale IP from the previous step.

The quick start uses `nip.io` so you do not need to edit hosts files or set up a DNS server.

## 4. Create Homepage links

Run this command so Homepage shows the correct private app links:

    set -a
    . ./.env
    set +a
    envsubst < config/homepage/services.yaml.template > config/homepage/services.yaml

If `envsubst` is missing, install it with:

    sudo apt install -y gettext-base

## 5. Start the stack

Run:

    docker compose up -d

## 6. Run checks

After the stack starts, run:

    ./scripts/healthcheck.sh
    ./scripts/exposure-check.sh

The health check confirms the main services and private URLs. The exposure check confirms local Docker and host bindings. It cannot prove whether your router or firewall has public port forwarding enabled.

## 7. Open the apps

Replace `100.x.x.x` with your server's Tailscale IP:

    http://homepage.100.x.x.x.nip.io
    http://uptime.100.x.x.x.nip.io
    http://whoami.100.x.x.x.nip.io

Open these from a device connected to your Tailscale network.

## Expected results

- Homepage loads.
- Uptime Kuma may redirect to `/dashboard`.
- Whoami shows request details.
- The Traefik dashboard returns `404` because it is disabled by default.

## If something fails

Use the [troubleshooting guide](08-troubleshooting.md) for common first-run problems.

## Before adding more apps

Before expanding the stack:

- run `./scripts/healthcheck.sh`
- run `./scripts/exposure-check.sh`
- review the [security checklist](07-security-checklist.md)
- read the [support boundaries](09-support-boundaries.md)
- add one app at a time

Keep the base stack working before adding more services.

# Private Homelab Gateway Kit

Secure remote access to your homelab apps with **Tailscale + Traefik**, without opening public ports.

Current release: `0.1.0-free`

## What this is

Private Homelab Gateway Kit is a beginner-friendly Docker deployment kit for safely accessing self-hosted apps from private devices.

It is designed for people running a small homelab on a:

- mini PC
- NAS
- old office PC
- Ubuntu or Debian server
- Proxmox VM or LXC container
- home server running Docker

The goal is simple:

> Access your self-hosted apps remotely through your private Tailscale network, without exposing them to the public internet.

## What is included

This kit includes:

- Traefik reverse proxy
- Homepage dashboard
- Uptime Kuma private monitoring dashboard
- Whoami test app
- Docker network with simple defaults
- Example environment file
- Basic setup and testing notes

## What this is not

This project is intentionally narrow.

It is **not**:

- a piracy or media-downloading stack
- an ARR stack
- a torrenting setup
- a Cloudflare Tunnel setup
- a Kubernetes project
- a public web-hosting guide
- a large collection of unrelated Docker apps
- a replacement for learning basic server security

This kit is focused on lawful self-hosting, private access, dashboards, monitoring, personal media, backups, and home-server administration.

## Core idea

Your device connects to your private Tailscale network. Tailscale reaches your homelab server. Traefik receives the request and routes it to the correct self-hosted app.

The recommended setup does not require opening public router ports.

## Requirements

You need:

- a Linux server, VM, or LXC container
- Docker
- Docker Compose
- Tailscale installed on the host
- a Tailscale account
- basic terminal access

Target platforms:

- Ubuntu Server
- Debian
- Proxmox VM
- Proxmox LXC with Docker support

## Before you start

Before running this kit, check that:

- Docker is installed on the server
- Docker Compose works with `docker compose`
- Tailscale is installed on the host server
- the server is connected to your Tailscale network
- your terminal account can run Docker commands
- you have not opened public router ports for this stack

Useful checks:

    docker compose version
    tailscale status
    tailscale ip -4

## Quick start

### 1. Copy the environment file

Run:

    cp .env.example .env

### 2. Find your Tailscale IP

Run:

    tailscale ip -4

### 3. Edit `.env`

Run:

    nano .env

Set:

    TAILSCALE_IP=100.x.x.x
    BASE_DOMAIN=100.x.x.x.nip.io
    HOMEPAGE_ALLOWED_HOSTS=homepage.100.x.x.x.nip.io

Replace `100.x.x.x` with your server's real Tailscale IP.

This quick-start uses `nip.io` so you do not need to edit hosts files or run your own DNS server.

Privacy note: `nip.io` hostnames include your Tailscale IP, and those names may appear in DNS queries. This does not open public router ports or make your apps reachable without access to your Tailscale network.

### Create Homepage links

Run this command so Homepage shows the correct private app links:

    set -a
    . ./.env
    set +a
    envsubst < config/homepage/services.yaml.template > config/homepage/services.yaml

If `envsubst` is missing, install it with:

    sudo apt install -y gettext-base

### 4. Start the stack

Run:

    docker compose up -d

### 5. Test Whoami through Traefik

Replace `100.x.x.x` with your server's Tailscale IP:

    curl -H "Host: whoami.100.x.x.x.nip.io" http://100.x.x.x

If working, you should see a response from the Whoami container.

### 6. Test Homepage

Run:

    curl -I -H "Host: homepage.100.x.x.x.nip.io" http://100.x.x.x

Expected:

    HTTP/1.1 200 OK

### 7. Test Uptime Kuma

Run:

    curl -I -H "Host: uptime.100.x.x.x.nip.io" http://100.x.x.x

Expected:

    HTTP 200, 302, or 307

A redirect to `/dashboard` is expected.

## What success looks like

After setup:

- `docker compose ps` shows Traefik, Homepage, Uptime Kuma, and Whoami running
- Homepage returns `HTTP/1.1 200 OK`
- Uptime Kuma is available through the private gateway
- Whoami returns request details
- the Traefik dashboard returns `404` because it is disabled by default
- Traefik is bound to your Tailscale IP, not `0.0.0.0`

Useful checks:

    docker compose ps
    curl -I -H "Host: homepage.100.x.x.x.nip.io" http://100.x.x.x
    curl -I -H "Host: uptime.100.x.x.x.nip.io" http://100.x.x.x
    curl -H "Host: whoami.100.x.x.x.nip.io" http://100.x.x.x

This should return `404`, which is expected because the Traefik dashboard is disabled:

    curl -I -H "Host: traefik.100.x.x.x.nip.io" http://100.x.x.x/dashboard/
    ss -tulpn | grep ':80'

In the commands above, replace `100.x.x.x` with your server's Tailscale IP.

## Run the health check

After the stack is running, you can run the health check:

    ./scripts/healthcheck.sh

It checks the required commands, `.env`, Tailscale, generated Homepage links, Docker Compose, expected containers, private app URLs, the disabled Traefik dashboard, and the port `80` binding.

## Run the exposure check

To check local Docker and host port bindings, run:

    ./scripts/exposure-check.sh

This checks whether Traefik is bound to the configured Tailscale IP and warns if common public all-interface bindings are detected. It cannot prove whether your router or firewall has public port forwarding enabled.

## Default apps

| App         | Purpose            | Quick-start hostname                           |
|-------------|--------------------|------------------------------------------------|
| Traefik     | Reverse proxy      | Runs internally; dashboard disabled by default |
| Homepage    | Dashboard          | homepage.100.x.x.x.nip.io                      |
| Uptime Kuma | Private monitoring | uptime.100.x.x.x.nip.io                        |
| Whoami      | Test app           | whoami.100.x.x.x.nip.io                        |

Traefik is included as the reverse proxy, but its dashboard is disabled by default to reduce unnecessary exposure. Uptime Kuma is included for private monitoring and is not publicly exposed. Homepage, Uptime Kuma, and Whoami are the first apps you will test through the private gateway.

## Custom DNS names

Clean names such as `homepage.homelab.test`, `whoami.homelab.test`, or `homepage.homelab.home.arpa` require custom DNS.

They are not the default quick-start path because they usually require router DNS rewrites, Tailscale split DNS, a real domain, or another private DNS setup.

## Security model

This kit assumes:

- public router ports remain closed
- access happens through Tailscale
- Traefik binds to the host's Tailscale IP
- apps are not directly published to the internet
- users intentionally choose which apps are routed

The default design avoids exposing Docker apps with broad `0.0.0.0` port bindings.

## Important safety notes

- Do not open public router ports for this stack.
- Do not change the Traefik port binding to `0.0.0.0` unless you understand the risk.
- `.env` contains your real Tailscale IP and should not be shared, uploaded, or committed.
- `nip.io` is for easy first setup. It includes your Tailscale IP in the hostname.
- The Traefik dashboard is disabled by default.
- Docker socket mounts are powerful. Treat containers with Docker socket access as trusted-host access.

See the [security checklist](docs/07-security-checklist.md) before adding more apps.

## Common first-run problems

- `404` from Traefik usually means the hostname does not match `BASE_DOMAIN`.
- Homepage host validation errors usually mean `HOMEPAGE_ALLOWED_HOSTS` is wrong.
- If your browser cannot open the URL, Tailscale may not be connected or DNS may not resolve.
- If the stack fails with a port bind error, `TAILSCALE_IP` may be wrong or port `80` may already be in use.
- If `envsubst` is missing, install `gettext-base`.

## Where to read next

- Follow the [quick-start guide](docs/01-quick-start.md) for the full setup flow.
- Read the [architecture guide](docs/02-architecture.md) for the high-level design.
- Read the [Tailscale guide](docs/03-tailscale.md) to understand private host access.
- Read the [Traefik guide](docs/04-traefik.md) to understand private app routing.
- Read the [DNS options guide](docs/05-dns-options.md) before changing app hostnames.
- Read the [adding apps guide](docs/06-adding-apps.md) before routing new services.
- Review the [security checklist](docs/07-security-checklist.md) before adding more apps.
- Use the [troubleshooting guide](docs/08-troubleshooting.md) for common first-run problems.
- Read the [support boundaries](docs/09-support-boundaries.md) before expanding the stack.
- Re-run the success checks after changing `.env` or adding a new service.
- Keep the stack small until Homepage, Uptime Kuma, and Whoami work reliably.

## Starter release

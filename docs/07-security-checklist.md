# Security Checklist

## What this checklist is for

Use this checklist before and after starting QuietGate.

The goal is to access self-hosted apps through Tailscale and Traefik without opening public router ports. This checklist helps confirm that the stack is still using the intended private-access model.

## Before starting

- Confirm there is no public router port forwarding for this stack.
- Confirm Tailscale is installed on the host server.
- Confirm the host server is connected to your Tailscale network.
- Confirm `.env` exists locally and is not shared, uploaded, or committed.
- Confirm `TAILSCALE_IP` in `.env` is the server's Tailscale IPv4 address.
- Confirm the Traefik port binding uses the Tailscale IP, not `0.0.0.0`.

Useful checks:

    tailscale status
    tailscale ip -4
    test -f .env && echo ".env exists"

## After running the stack

- Confirm Traefik, Homepage, Uptime Kuma, and Whoami are running.
- Confirm the generated Homepage services config exists.
- Confirm Homepage responds through the expected private hostname.
- Confirm Uptime Kuma responds through the expected private hostname.
- Confirm Whoami responds through the expected private hostname.
- Confirm the Traefik dashboard is not exposed. It is disabled by default.
- Confirm Traefik is listening on the Tailscale IP, not every network interface.

Useful checks:

    docker compose ps
    test -f config/homepage/services.yaml && echo "Homepage services config exists"
    ss -tulpn | grep ':80'
    ./scripts/exposure-check.sh

If `ss` shows `0.0.0.0:80`, stop and review the Traefik port binding before continuing.

## Docker socket warning

This kit uses Docker labels so Traefik can discover routed apps.

Docker socket mounts are powerful. A container with Docker socket access should be treated as trusted-host access, even when the mount is read-only in the Compose file.

For this stack:

- keep Docker socket access limited to containers that need it
- do not add random containers with Docker socket access
- review any app before giving it access to `/var/run/docker.sock`

## DNS and nip.io note

The quick start uses `nip.io` to avoid hosts-file edits and custom DNS setup.

This is useful for beginners, but it has a privacy trade-off:

- the hostname includes your Tailscale IP
- the hostname may appear in DNS queries
- this does not open public router ports
- this does not make the app reachable without access to your Tailscale network

For a cleaner private name later, use a custom DNS setup such as router DNS rewrites, Tailscale split DNS, or an owned domain with private records.

## What not to change casually

Avoid changing these defaults unless you understand the security impact:

- do not open public router ports for this stack
- do not bind Traefik to `0.0.0.0`
- do not enable the Traefik dashboard without adding access controls
- do not share, upload, or commit `.env`
- do not route apps accidentally; only add Traefik labels for apps you intend to expose through the private gateway
- do not add broad stacks or services that increase support and security complexity

Keep this stack narrow. Do not add ARR stacks, torrent clients, VPN containers, Cloudflare Tunnel, Kubernetes, Authentik, or public port forwarding.

## Updates and changes

Update containers carefully:

- read release notes before major version updates
- update one part at a time when possible
- restart the stack cleanly
- test Homepage, Uptime Kuma, and Whoami after changes
- check the listening address again after changes

After changing ports, app labels, or network settings, repeat the checks above and run `./scripts/exposure-check.sh` before assuming the setup is still private.

## When to stop and troubleshoot

Stop and troubleshoot before adding more apps if:

- Traefik is listening on `0.0.0.0`
- the stack only works after opening a public router port
- `.env` is missing or was accidentally shared, uploaded, or committed
- Homepage, Uptime Kuma, or Whoami responds on an unexpected hostname
- the Traefik dashboard is reachable
- an app needs Docker socket access and you are not sure why
- you are unsure whether a new app should be routed

When something is unclear, keep the stack small and fix the base setup first.

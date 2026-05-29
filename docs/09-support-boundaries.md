# Support Boundaries

Private Homelab Gateway Kit is designed to be beginner-friendly, but it cannot cover every possible homelab setup.

The goal is to provide a small, security-focused base stack for private remote access through Tailscale and Traefik. Keep the base stack working before adding more apps or custom networking.

## What is included

This kit focuses on:

- base stack setup
- Traefik, Homepage, Uptime Kuma, and Whoami as included services
- the Tailscale host access concept
- reading and acting on `./scripts/healthcheck.sh` results
- reading and acting on `./scripts/exposure-check.sh` results
- documentation corrections
- security-focused improvements

The included services are meant to prove the private gateway pattern:

- Traefik receives private requests and routes them to apps.
- Homepage gives you a private dashboard.
- Uptime Kuma gives you private monitoring.
- Whoami confirms routing is working.

## What is outside scope

These areas are outside the scope of this kit:

- ARR stacks
- torrent clients
- download automation
- VPN containers
- Cloudflare Tunnel
- Kubernetes
- Authentik or other SSO systems
- public port forwarding
- arbitrary Docker apps
- complex custom firewall, router, or VLAN setups
- open-ended custom debugging for every individual environment

Keeping these areas out of the base kit helps keep setup, troubleshooting, and security review manageable.

## Jellyfin note

Jellyfin may be included later as an optional example.

If included, it should be treated as an example only. It is not a promise of custom transcoding support, hardware acceleration support, media library support, or device-specific playback troubleshooting.

## Before adding more apps

Before adding more services, confirm that:

- Homepage works through the private gateway
- Uptime Kuma works through the private gateway
- Whoami works through the private gateway
- `./scripts/healthcheck.sh` passes
- `./scripts/exposure-check.sh` passes
- Traefik is not listening on `0.0.0.0`
- you have not opened public router ports for this stack

Add one app at a time. After each change, re-run the checks before moving on.

## When to use the troubleshooting guide

Use the troubleshooting guide when:

- the browser cannot open a private app URL
- Traefik returns `404`
- Homepage reports a host validation problem
- Docker Compose validation fails
- the health check or exposure check fails

Start with the base stack before debugging optional apps.

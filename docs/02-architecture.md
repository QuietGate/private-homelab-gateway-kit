# Architecture

QuietGate is built around one idea: private access first.

Your apps are reached through Tailscale and Traefik, without opening public router ports for the base stack.

## High-level flow

The request flow is:

    user device on Tailscale
    -> server Tailscale IP
    -> Traefik bound to ${TAILSCALE_IP}:80
    -> Docker gateway network
    -> app container

## Simple diagram

```
Phone, laptop, or tablet
connected to Tailscale
        |
        v
Server Tailscale IP
        |
        v
Traefik
listening on ${TAILSCALE_IP}:80
        |
        v
Docker gateway network
        |
        +--> Homepage
        +--> Uptime Kuma
        +--> Whoami
```

## What each component does

### Tailscale

Tailscale provides private network access to the server.

For this kit, Tailscale runs on the host server, not inside Docker. Your device connects to Tailscale, then reaches the server's Tailscale IP.

### Traefik

Traefik is the private reverse proxy and router.

It listens on `${TAILSCALE_IP}:80`, reads Docker labels, and routes each hostname to the right container.

### Docker gateway network

The Docker `gateway` network is the private container network used by this stack.

Apps attach to this network so Traefik can reach them without each app publishing its own host port.

### Homepage

Homepage is the private dashboard.

It gives you a simple place to link to the apps in this kit.

### Uptime Kuma

Uptime Kuma is the private monitoring dashboard.

It can be used to monitor services from inside your private setup.

### Whoami

Whoami is a small routing test app.

If Whoami works through Traefik, the basic private routing path is working.

### .env

`.env` stores local configuration for your server.

Important values include:

    TAILSCALE_IP=100.x.x.x
    BASE_DOMAIN=100.x.x.x.nip.io

Do not share, upload, or commit `.env`.

### scripts/healthcheck.sh

`scripts/healthcheck.sh` checks whether the stack works.

It checks required commands, `.env`, Tailscale, generated Homepage links, Docker Compose, expected containers, private app URLs, the disabled Traefik dashboard, and the port `80` binding.

### scripts/exposure-check.sh

`scripts/exposure-check.sh` checks local host and Docker bindings.

It helps confirm that Traefik is bound to the configured Tailscale IP and warns about common all-interface bindings. It cannot prove whether your router or firewall has public port forwarding enabled.

## Why public router ports are not required

Tailscale creates the private path between your device and the server.

Because your device reaches the server through Tailscale, the base stack does not need public router port forwarding.

Do not open public router ports for the default setup.

## Why Traefik is the only host-published entry point

Traefik is the only service that should publish a host port in the base stack.

This keeps the model simple:

- one private entry point
- one place to check exposure
- one routing layer for app hostnames

## Why apps stay on the Docker network

Apps should stay on the Docker `gateway` network and avoid direct `ports:` mappings unless there is a clear reason.

This keeps app traffic behind Traefik and makes it easier to understand what is reachable.

## How app hostnames work

Traefik routes requests by hostname.

The base app hostnames are:

    homepage.${BASE_DOMAIN}
    uptime.${BASE_DOMAIN}
    whoami.${BASE_DOMAIN}

With the quick start, `BASE_DOMAIN` looks like:

    100.x.x.x.nip.io

So the app hostnames look like:

    homepage.100.x.x.x.nip.io
    uptime.100.x.x.x.nip.io
    whoami.100.x.x.x.nip.io

## What is intentionally not included

The base architecture intentionally does not include:

- Authentik or other SSO systems
- ARR stacks
- torrent clients
- VPN containers
- Cloudflare Tunnel
- Kubernetes
- public port forwarding

Leaving these out keeps the base setup smaller, easier to understand, and easier to check.

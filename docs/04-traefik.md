# Traefik Guide

Traefik is the reverse proxy in Private Homelab Gateway Kit.

It receives private HTTP requests from your Tailscale network, reads Docker labels, and routes each request to the correct app container.

## Request flow

The basic request flow is:

    device on Tailscale
    -> server Tailscale IP
    -> Traefik
    -> app container

The app containers do not need to publish their own ports to the host. Traefik is the single private entry point for the stack.

## Why Traefik binds to the Tailscale IP

Traefik should bind to:

    ${TAILSCALE_IP}:80

It should not bind to:

    0.0.0.0:80

`0.0.0.0` means every network interface on the server. The intended default is narrower: Traefik listens on the server's Tailscale IP so requests come through the private Tailscale path.

This helps avoid accidentally exposing the reverse proxy on interfaces that are not part of the private Tailscale setup.

## Why apps should not publish ports directly

In this kit, apps should usually avoid direct `ports:` mappings.

Instead:

- Traefik listens on the host
- apps stay on the Docker network
- Traefik routes to apps by container name and internal port

This keeps the exposure model simpler. If every app publishes its own host port, it becomes harder to know what is reachable and where.

## How Traefik labels work

Traefik reads Docker labels from each service.

For an app to be routed, it needs labels like these:

    traefik.enable=true
    traefik.http.routers.example.rule=Host(`example.${BASE_DOMAIN}`)
    traefik.http.routers.example.entrypoints=web
    traefik.http.services.example.loadbalancer.server.port=3000

What these mean:

- `traefik.enable=true` tells Traefik this app should be routed.
- `Host(\`example.${BASE_DOMAIN}\`)` tells Traefik which hostname should reach the app.
- `entrypoints=web` means the route uses the HTTP entrypoint.
- the service port label tells Traefik which internal container port to use.

The service port is the app's port inside Docker. It is not the same as publishing a port directly on the host.

## What BASE_DOMAIN means

`BASE_DOMAIN` is the shared domain pattern used by your app hostnames.

The quick start uses:

    BASE_DOMAIN=100.x.x.x.nip.io

That gives app URLs such as:

    homepage.100.x.x.x.nip.io
    uptime.100.x.x.x.nip.io
    whoami.100.x.x.x.nip.io

Replace `100.x.x.x` with your server's Tailscale IP.

Cleaner names can be used later, but they require custom DNS.

## Why the Traefik dashboard is disabled

The Traefik dashboard is disabled by default to reduce unnecessary exposure.

For the starter setup, you do not need the dashboard to confirm routing works. Homepage, Uptime Kuma, Whoami, the health check, and the exposure check are enough for the first-run workflow.

Do not enable the dashboard casually. If you enable it later, add access controls first.

## Verify Traefik routes

To see the routes Traefik will read from Docker labels, run:

    docker compose config | grep -n "traefik.http.routers"

To check the running stack, run:

    ./scripts/healthcheck.sh
    ./scripts/exposure-check.sh

The health check confirms expected app routes. The exposure check confirms local host and Docker bindings.

## Common mistakes

- `BASE_DOMAIN` does not match the hostname you are using.
- Labels were changed but the stack was not restarted.
- An app publishes its own host port directly.
- Traefik is changed to bind to `0.0.0.0`.
- The Traefik dashboard is enabled without access controls.

If something breaks, keep the stack small and return to the quick-start checks before adding more services.

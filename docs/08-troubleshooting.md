# Troubleshooting

This guide covers common first-run problems with QuietGate.

Keep the stack small while troubleshooting. Get Homepage, Uptime Kuma, and Whoami working through Tailscale before adding more apps.

## Before troubleshooting

Run the built-in checks first:

    ./scripts/healthcheck.sh
    ./scripts/exposure-check.sh

Then confirm the basics:

    tailscale status
    test -f .env && echo ".env exists"
    test -f config/homepage/services.yaml && echo "Homepage services config exists"

The server should be connected to Tailscale, `.env` should exist, and the generated Homepage services config should exist.

## 404 page not found

A `404 page not found` response from Traefik usually means Traefik is reachable, but no router matched the hostname you used.

Common causes:

- `BASE_DOMAIN` in `.env` does not match the hostname in your browser or curl command.
- You are using a name like `homelab.test` without custom DNS.
- You changed `.env` but did not regenerate `config/homepage/services.yaml`.
- The URL is wrong, such as `whoami` instead of `whoami.${BASE_DOMAIN}`.

Useful commands:

    docker compose config | grep -n "traefik.http.routers"
    tailscale ip -4

If you are using the quick-start path, the hostname should look like `homepage.100.x.x.x.nip.io`, with `100.x.x.x` replaced by your server's Tailscale IP.

## Homepage host validation failed

Homepage checks that requests use an allowed hostname.

If Homepage shows a host validation error, check `HOMEPAGE_ALLOWED_HOSTS` in `.env`. It should match the hostname you use for Homepage.

For the quick start, it should look like:

    HOMEPAGE_ALLOWED_HOSTS=homepage.100.x.x.x.nip.io

After changing `.env`, regenerate the Homepage services config:

    set -a
    . ./.env
    set +a
    envsubst < config/homepage/services.yaml.template > config/homepage/services.yaml

Then restart the stack:

    docker compose up -d

## Browser cannot open the URL

If the browser cannot open the URL at all, the request may not be reaching the server.

Common causes:

- the device is not connected to Tailscale
- `TAILSCALE_IP` in `.env` is wrong
- DNS cannot resolve the `nip.io` hostname
- the stack is not running

Useful checks:

    tailscale status
    tailscale ip -4
    docker compose ps

Do not open public router ports to fix this. The intended path is through Tailscale.

## Uptime Kuma redirects to /dashboard

Uptime Kuma may return a `302` redirect to `/dashboard` on first access.

That redirect is expected. It means the request reached Uptime Kuma through Traefik.

## Traefik dashboard returns 404

This is expected.

The Traefik dashboard is disabled by default to reduce unnecessary exposure. A `404` response for the dashboard route means it is not being routed by Traefik.

## Port 80 already in use

If the stack fails with a port bind error, another process may already be using port `80`.

Check with:

    ss -tulpn | grep ':80'

Keep the fix local to the server. Do not open public router ports.

## Traefik is listening on 0.0.0.0

This is not the intended default.

Traefik should bind to your server's Tailscale IP, not `0.0.0.0`. If you see `0.0.0.0:80`, stop and review the Traefik port binding before continuing.

Useful check:

    ./scripts/exposure-check.sh

## Docker Compose validation fails

If Docker Compose validation fails, check for:

- YAML indentation problems
- missing values in `.env`
- accidental edits to service names, labels, or ports

Run:

    docker compose config

Read the first error message carefully. It usually points close to the problem.

## Generated Homepage links are wrong

If Homepage shows old or incorrect links, regenerate the services config from `.env`:

    set -a
    . ./.env
    set +a
    envsubst < config/homepage/services.yaml.template > config/homepage/services.yaml

Then restart the stack:

    docker compose up -d

## When to stop

Stop before adding more apps if:

- `./scripts/healthcheck.sh` fails
- `./scripts/exposure-check.sh` fails
- Traefik binds to `0.0.0.0`
- access only works after opening a public router port
- you are unsure why a service needs Docker socket access

Fix the base setup first, then add more apps one at a time.

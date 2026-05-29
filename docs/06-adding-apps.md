# Adding Apps

This guide explains the safe pattern for adding more Docker apps to Private Homelab Gateway Kit.

Keep the base stack working before adding more services. Add one app at a time, then test before moving on.

## Safe app pattern

Use this pattern for most apps:

- keep Traefik as the only host-published entry point
- do not publish app ports directly unless there is a clear reason
- attach apps to the `gateway` network
- add Traefik labels intentionally
- use `app.${BASE_DOMAIN}` hostnames

The goal is simple: Traefik receives the private request and sends it to the app inside Docker.

## Generic Compose example

This is a generic example. Replace the image, container name, router name, hostname, and internal port for the app you are adding.

```yaml
  example:
    image: example/image:latest
    container_name: phgk-example
    restart: unless-stopped

    networks:
      - gateway

    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.example.rule=Host(`example.${BASE_DOMAIN}`)"
      - "traefik.http.routers.example.entrypoints=web"
      - "traefik.http.services.example.loadbalancer.server.port=3000"
```

Do not add `ports:` unless you understand why the app needs a direct host port.

## Find the internal app port

The Traefik service port label must use the app's internal container port.

Look in the app's documentation for phrases like:

- listens on port
- web UI port
- container port
- exposed port

For example, if the app documentation says the web UI runs inside the container on port `3000`, the label should be:

```yaml
      - "traefik.http.services.example.loadbalancer.server.port=3000"
```

This does not publish port `3000` on the host. It only tells Traefik where to send traffic inside Docker.

## Add a Homepage link

Edit:

    config/homepage/services.yaml.template

Add a new entry using the same hostname pattern:

```yaml
    - Example:
        href: http://example.${BASE_DOMAIN}
        description: Private app
        icon: docker.svg
```

Then regenerate the Homepage services config:

    set -a
    . ./.env
    set +a
    envsubst < config/homepage/services.yaml.template > config/homepage/services.yaml

## Test the change

Validate the Compose file:

    docker compose config

Start or update the stack:

    docker compose up -d

Test the new app route. Replace `100.x.x.x` with your server's Tailscale IP:

    curl -I http://example.100.x.x.x.nip.io

Run the checks:

    ./scripts/healthcheck.sh
    ./scripts/exposure-check.sh

## Common mistakes

- using the wrong internal app port
- forgetting to attach the app to the `gateway` network
- forgetting to regenerate Homepage links
- adding `ports:` unnecessarily
- changing `BASE_DOMAIN` without updating `.env` and regenerating Homepage config

If Traefik returns `404`, check the hostname and labels first.

## Security reminders

- only route apps you intend to access
- do not add apps you do not trust
- do not give Docker socket access unless needed
- keep the base stack working before adding more apps
- add one app at a time and test after each change

Keep the default setup small and predictable. The safer path is to expand slowly and verify each change.

# DNS Options

QuietGate uses hostnames so Traefik can route each request to the right app.

The quick start uses `nip.io` because it is the lowest-friction way to get working private URLs without editing hosts files or running your own DNS server.

## Why the quick start uses nip.io

`nip.io` is useful for first setup because:

- it works without hosts-file edits
- it works without running a DNS server
- it lets you test Traefik hostnames quickly
- it keeps the base stack small

The trade-off is privacy: the hostname includes your Tailscale IP, and that hostname may appear in DNS queries.

This does not open public router ports. It only helps devices resolve the hostname to the Tailscale IP.

## What BASE_DOMAIN does

`BASE_DOMAIN` is the shared domain pattern used by app hostnames.

For the quick start:

    BASE_DOMAIN=100.x.x.x.nip.io

App hostnames are built from it:

    homepage.100.x.x.x.nip.io
    uptime.100.x.x.x.nip.io
    whoami.100.x.x.x.nip.io

Replace `100.x.x.x` with your server's Tailscale IP.

## Why clean names require DNS

Clean names such as these do not work by themselves:

    homepage.homelab.home.arpa
    uptime.homelab.home.arpa

They require DNS that tells your device where those names should go.

That DNS can come from a router, a local DNS resolver, Tailscale DNS settings, or records on an owned domain.

## Option comparison

| Option | Difficulty | Works without extra DNS | Privacy notes | Recommended use |
|--------|------------|-------------------------|---------------|-----------------|
| `nip.io` quick start | Low | Yes | Hostname includes the Tailscale IP and may appear in DNS queries | Default first setup |
| Tailscale MagicDNS | Low | Partly | Good for device names, not automatic per-app names | Useful background feature |
| Router/local DNS rewrites | Medium | No | Private to your local DNS setup | Good later for LAN-friendly names |
| Tailscale custom DNS / split DNS | Medium/high | No | Private if your DNS resolver is private | Good later for Tailnet-friendly names |
| Real owned domain with private records | Medium | Yes, if records are public DNS records | Public DNS records may reveal service names | Polished later option |

## Tailscale MagicDNS

Tailscale MagicDNS is useful for reaching devices by their Tailscale device names.

It does not automatically create per-app Traefik hostnames such as:

    homepage.homelab.home.arpa
    uptime.homelab.home.arpa

Traefik routes apps by hostname, so each app hostname still needs to resolve to the server's Tailscale IP.

## Router or local DNS rewrites

Some routers let you create local DNS rewrites.

For example, you could make:

    homepage.homelab.home.arpa

resolve to the server's Tailscale IP or another private address you intentionally use.

This can work well at home, but every router is different. That makes it a better later option than a default quick-start path.

## Tailscale custom DNS or split DNS

Tailscale DNS settings can send certain private names to a DNS resolver you choose.

This can be useful if you want clean names across devices connected to Tailscale.

It is more advanced than the quick start because you need a DNS resolver and a clear naming plan.

## Real owned domain with private records

If you own a domain, you can create records such as:

    homepage.home.example
    uptime.home.example

that point to the server's Tailscale IP.

This can feel polished and works without editing hosts files, but public DNS records may reveal service names. Use this only if you are comfortable with that trade-off.

## Suffix guidance

- Avoid `.local` as the default. It can conflict with mDNS and Bonjour behavior.
- `.test` is safe for examples, but it does not resolve without DNS.
- `.home.arpa` is a good private home-network suffix.
- A real owned domain can be polished, but public records may expose service names.

## Recommended path

Start with:

    BASE_DOMAIN=100.x.x.x.nip.io

After the base stack is working, you can move to:

- `.home.arpa` with router or private DNS
- an owned domain if you understand the privacy trade-off

Do not add a DNS server container to the base stack. Keep the default setup small and easy to troubleshoot.

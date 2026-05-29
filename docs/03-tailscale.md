# Tailscale Guide

QuietGate uses Tailscale as the private access layer.

For this kit, Tailscale is installed on the host server. It is not run as a Docker container.

## Why Tailscale runs on the host

Host-installed Tailscale is the default because it keeps the setup simpler:

- the mental model is easier to understand
- troubleshooting is easier
- Traefik can bind directly to the server's Tailscale IP
- fewer Docker permissions and capabilities are needed
- it fits Proxmox VMs, Proxmox LXCs, Ubuntu, Debian, and beginner setups well

With this model, Docker apps do not need to know how Tailscale works. Traefik receives private traffic from the host and routes it to the right container.

## Request flow

The basic request flow is:

    user device
    -> Tailscale network
    -> server Tailscale IP
    -> Traefik
    -> Docker app

This means your apps are reached through your private Tailscale network, not through public router ports.

## Confirm Tailscale is working

Run:

    tailscale status
    tailscale ip -4

`tailscale status` should show that the server is connected to your Tailscale network.

`tailscale ip -4` should print the server's Tailscale IPv4 address.

## How .env uses the Tailscale IP

Your `.env` file uses the server's Tailscale IP in two places:

    TAILSCALE_IP=100.x.x.x
    BASE_DOMAIN=100.x.x.x.nip.io

Replace `100.x.x.x` with your own Tailscale IP.

`TAILSCALE_IP` tells Docker which host address Traefik should bind to.

`BASE_DOMAIN` gives you simple quick-start hostnames such as:

    homepage.100.x.x.x.nip.io
    uptime.100.x.x.x.nip.io
    whoami.100.x.x.x.nip.io

## Why public router ports are not required

Tailscale creates a private network between your devices.

When your phone, laptop, or other device is connected to Tailscale, it can reach the server's Tailscale IP directly. Your router does not need to forward public ports for this stack.

Do not open public router ports for the default setup.

## Why Tailscale-in-Docker is not the default

Some advanced users run Tailscale inside Docker. That is not the default path for this kit.

Tailscale-in-Docker can require:

- extra container permissions
- access to `/dev/net/tun`
- additional networking choices
- more troubleshooting when something fails

It can also be harder in Proxmox LXC environments.

Advanced users may choose that approach for their own systems, but host-installed Tailscale is the default path for this kit.

## If tailscale ip -4 is empty

If this command prints nothing:

    tailscale ip -4

Check Tailscale status:

    tailscale status

Make sure the Tailscale service is running:

    sudo systemctl status tailscaled
    sudo systemctl start tailscaled

If the server is not connected yet, run:

    sudo tailscale up

If you are using a Proxmox LXC and Tailscale still cannot start, check that the container has TUN access enabled. Without TUN access, Tailscale may not be able to create its network interface.

After fixing Tailscale, run:

    tailscale ip -4

Then update `.env` with the correct Tailscale IP before starting the stack.

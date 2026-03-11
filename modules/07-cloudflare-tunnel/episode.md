# Episode 7: Zero Open Ports -- Cloudflare Tunnel

## Exposing Services Without Exposing Your Server

### In This Episode

Here's the magic trick of this entire course: your VPS has zero open ports (except SSH for you), yet WhatsApp can still deliver messages to it. How? Cloudflare Tunnel creates an outbound-only connection from your server to Cloudflare's edge network. Traffic flows *through* that tunnel -- your server is invisible to the internet. No port scanners can find it. No bots can probe it. This is the single biggest security win in the entire setup, and honestly, it's one of those ideas that makes you go "wait, that's *brilliant*."

### Key Concepts

- **Traditional webhooks vs tunnel** -- why opening port 443 is a liability, and how tunnels eliminate the problem entirely
- **Outbound-only connections** -- your server calls Cloudflare, not the other way around
- **DNS routing** -- how subdomains map through the tunnel to specific services on your VPS
- **The token method** -- the simplest way to configure a tunnel, especially for Docker
- **Zero open ports** -- what it means, why it matters, and how to prove it
- **Catch-all 404 rules** -- blocking anything you didn't explicitly allow

### Prerequisites

You should have completed Modules 4, 5, and 6. You need a running VPS with Docker installed, UFW configured (deny all inbound except SSH), and an understanding of Docker Compose and Docker networking.

> **Self-check:** Can you SSH into your server, run `docker compose ps`, and explain what UFW is doing for you? You're ready.

### Builds On

- **Module 4: Containers** -- you'll add `cloudflared` as a new service in your Docker Compose file
- **Module 5: The Lethal Trifecta** -- this module eliminates the "open ports" leg; you already locked down UFW
- **Module 6: Secrets Management** -- your tunnel token is a secret, and you know how to treat it like one

### What's Next

In **Module 8: WhatsApp -- The Real Integration**, you'll configure Meta's webhook to point at your Cloudflare Tunnel URL. The tunnel you build here is what makes that possible -- WhatsApp messages will flow through it to reach OpenClaw on your locked-down server.

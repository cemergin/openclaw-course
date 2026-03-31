# Episode 8: Zero Open Ports -- Cloudflare Tunnel

## Exposing Services Without Exposing Your Server

### In This Episode

Here's the magic trick of this course: your VPS has zero open ports (well, maybe SSH), yet your monitoring dashboard is accessible from your phone and your kill switch works from anywhere. How? Cloudflare Tunnel creates an outbound-only connection from your server to Cloudflare's edge network. Traffic flows *through* that tunnel -- your server is invisible to the internet. No port scanners can find it. No bots can probe it. This is the single biggest security win in the entire setup.

### Key Concepts

- **Traditional port exposure vs tunnel** -- why opening ports is a liability, and how tunnels eliminate the problem
- **Outbound-only connections** -- your server calls Cloudflare, not the other way around
- **DNS routing** -- how subdomains map through the tunnel to specific services on your VPS
- **The token method** -- the simplest way to configure a tunnel for Docker
- **Hybrid routing** -- cloudflared (in Docker) routes to native OpenClaw on `localhost:18789` and to Docker services by container name
- **Zero open ports** -- what it means, why it matters, and how to prove it

### Prerequisites

You should have completed Module 7. You need a running VPS with OpenClaw running natively, Docker for support services, UFW configured (deny all inbound except SSH), and secrets management set up.

> **Self-check:** Can you SSH into your server, run `openclaw gateway status` to see your bot running, and explain why your Docker port bindings use `127.0.0.1:`? You're ready.

### Builds On

- **Module 4: Containers** -- you'll add `cloudflared` as a new service in your Docker Compose file
- **Module 7: The Lethal Trifecta** -- this module eliminates the "open ports" leg entirely
- **Module 7: Secrets** -- your tunnel token is a secret, and you know how to handle it

### What's Next

In **Module 9: Stay Alive -- Monitoring and Kill Switch**, you'll set up Uptime Kuma behind this tunnel so you can check your stack's health from your phone. The tunnel makes that possible without opening any ports. You'll also build a kill switch endpoint that lets you shut everything down in an emergency.

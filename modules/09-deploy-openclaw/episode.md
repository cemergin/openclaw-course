# Episode 9: Ship It -- Full Docker Compose Deployment

## Bringing Everything Together Into One docker-compose.yml

### In This Episode

This is the moment. Every skill you've built across eight modules -- VPS provisioning, SSH, Docker, security hardening, secrets management, Cloudflare Tunnel, WhatsApp integration -- all of it converges into a single `docker-compose.yml` file. You'll assemble your complete stack service by service, wire everything together with networks, volumes, secrets, and health checks, then bring it all up with one command. By the end, you'll send a WhatsApp message from your phone and get a response powered by Claude. That's not a simulation. That's your AI agent, running on your server, talking back to you.

### Key Concepts

- **Multi-service Docker Compose architecture** -- five services, one file, one command to run them all
- **Service dependencies** -- `depends_on` and health checks to ensure things start in the right order
- **Internal Docker networks** -- containers talking to each other by name, invisible to the outside world
- **Volume management** -- config, data, and repos each mapped to the right place
- **The onboarding flow** -- `openclaw onboard` walks you through first-time setup inside the container
- **Container lifecycle management** -- start, stop, restart, update, logs, shell access
- **Daily operations** -- the handful of commands you'll actually use every day

### Prerequisites

You should have completed Modules 4 through 8. You need a running VPS with Docker and Docker Compose installed, UFW configured, Docker file-based secrets created, a Cloudflare Tunnel configured with your domain, and a WhatsApp Business app with webhooks pointing at your tunnel URL.

> **Self-check:** Can you SSH into your server, run `docker compose version`, list your files in `~/openclaw-stack/secrets/`, and confirm your Cloudflare Tunnel is set up in the dashboard? If yes -- let's ship this thing.

### Builds On

- **Module 4: Containers** -- you know Docker Compose, volumes, networks, and port mapping
- **Module 5: The Lethal Trifecta** -- your security mental model guides every decision in this compose file
- **Module 6: Secrets Management** -- your API keys and tokens live in `secrets/` files, not `.env`
- **Module 7: Cloudflare Tunnel** -- your tunnel is configured and ready to route traffic
- **Module 8: WhatsApp Integration** -- your webhook URL points to your tunnel, Meta is configured

### What's Next

In **Module 10: Is It Still Alive? -- Monitoring and Alerts**, you'll configure Uptime Kuma (one of the services you just deployed) to actually watch your stack and alert you when something breaks. Right now your bot works -- next we make sure you *know* if it ever stops working.

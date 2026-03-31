# Episode 9: Monitoring + Kill Switch -- The Third Leg of the Lethal Trifecta

## Know When Things Break. Stop Them When They Don't.

### In This Episode

Your bot is deployed, secured behind a Cloudflare Tunnel, and secrets are locked away in files with SecretRef. Two legs of the lethal trifecta are handled. But right now, if OpenClaw crashes at 3 AM, you won't know until you try to message it tomorrow afternoon. And if it starts doing something unhinged -- burning through API credits in a loop, or obeying a prompt injection -- you have no way to stop it without SSHing in.

This module fixes both problems in one shot. First, you'll set up Uptime Kuma as a self-hosted monitoring dashboard with Telegram alerts, so you know within 60 seconds when something breaks. Then you'll build a kill switch -- a secret URL bookmarked on your phone that stops OpenClaw with a single tap. Monitoring tells you something is wrong. The kill switch lets you do something about it immediately.

Together, they complete the trifecta: tunnel locks the doors, secrets hide the keys, monitoring watches the cameras -- and the kill switch is the fire alarm you can pull from anywhere.

### Key Concepts

- **The trifecta, completed** -- open ports (tunnel), exposed secrets (SecretRef + Docker secrets), no monitoring (this module)
- **Uptime Kuma** -- self-hosted monitoring dashboard with push notifications, running in Docker
- **Health checks** -- monitoring that OpenClaw and supporting services are actually responding
- **Telegram notifications** -- reusing your existing bot for instant alerts on your phone
- **Alert fatigue** -- why monitoring everything is worse than monitoring nothing
- **Kill switch** -- a secret URL that stops native OpenClaw via `openclaw gateway stop`, bookmarked on your phone
- **Escalation levels** -- URL, SSH, provider app -- multiple ways to pull the plug
- **Why AI agents need kill switches** -- runaway costs, prompt injection, hallucination spirals

### Prerequisites

You should have completed Modules 0-8 and have a fully running stack: native OpenClaw with Cloudflare Tunnel routing traffic via Docker support services. Your Telegram bot should be set up from Module 0.

> **Self-check:** Can you run `openclaw gateway status` and see your bot is healthy? Can you run `docker compose ps` and see cloudflared running? Can you access your bot via Telegram and get a response? You're ready.

### What's Next

In **Module 10: Power Ups**, you'll connect your (now monitored, kill-switchable) AI agent to GitHub, Gmail, Notion, and more. More integrations means more reasons to have monitoring and a kill switch -- good thing you just built both.

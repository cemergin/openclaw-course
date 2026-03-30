# Episode 11: Is It Still Alive? -- Monitoring and Alerts

## Know When Things Break Before Your Bot Goes Silent

### In This Episode

Your bot could crash at 3 AM and you wouldn't know until you try to message it tomorrow afternoon. That's the "no monitoring" leg of the lethal trifecta from Module 5, and it's the last piece we need to close. You'll write a health check script that watches CPU, RAM, disk, and whether OpenClaw is actually running. Then you'll automate it with cron, set up Uptime Kuma for a proper monitoring dashboard with push notifications, and optionally add an external dead-man's switch so you get alerted even if your *server itself* is the thing that died. By the end, you'll know within 60 seconds when something goes wrong -- and you'll have the alerts to prove it.

### Key Concepts

- **The trifecta, completed** -- open ports (tunnel), exposed secrets (Docker Secrets), no monitoring (this module)
- **Health check scripts** -- simple bash that watches the vital signs: CPU, memory, disk, service status
- **Cron jobs** -- Linux's built-in scheduler for "run this every X minutes"
- **Uptime Kuma** -- self-hosted monitoring dashboard with notifications (already in your compose stack)
- **Dead-man's switch** -- external monitoring that alerts you when your server *stops* checking in
- **Alert fatigue** -- why monitoring everything is almost as bad as monitoring nothing
- **docker stats** -- reading container resource usage in real time

### Prerequisites

You should have completed Module 9 and have a fully running OpenClaw stack (OpenClaw, Cloudflared, SearXNG, and Uptime Kuma all running via Docker Compose). Your Cloudflare Tunnel should be working with subdomains configured.

> **Self-check:** Can you run `docker compose ps` from your `openclaw-stack` directory and see all services healthy? Can you access your bot via WhatsApp and get a response? You're ready.

### Builds On

- **Module 5: The Lethal Trifecta** -- you learned *why* no monitoring is dangerous; now we fix it
- **Module 7: Cloudflare Tunnel** -- Uptime Kuma's dashboard is exposed through your tunnel at `status.yourdomain.com`
- **Module 9: Ship It** -- your full stack is running; Uptime Kuma is already a service in your compose file

### What's Next

In **Module 12: The Kill Switch**, you'll build an emergency stop that works from your phone. Monitoring tells you something is wrong -- the kill switch lets you *do* something about it instantly, without needing to SSH in. Together, they form your incident response: detect fast, act faster.

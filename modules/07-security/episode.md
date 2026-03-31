# Episode 7: The Lethal Trifecta (And How Not to Die)

## Security Fundamentals + Secrets Management for the Hybrid Stack

### In This Episode

Your bot works. It responds to messages, it talks to Claude, it does its thing. Here's the problem: right now it's a sitting duck. Your server has open ports that anyone can find, your API keys are probably sitting in a `.env` file that takes four seconds to steal, and you have zero idea if someone is already poking around in there. These three things -- open ports, exposed secrets, no monitoring -- are what we call the "lethal trifecta," and having all three at once is basically handing your credit card to the internet. In this module, we're going to fix the first two and build the awareness for the third.

There's a twist, though. Our stack is hybrid: OpenClaw runs natively on the VPS (not in Docker), while support services like cloudflared, Uptime Kuma, and the kill switch run in Docker containers. That means secrets management works differently for each side -- and the firewall has a critical blind spot you need to understand.

### Key Concepts

- **The lethal trifecta** -- open ports + exposed secrets + no monitoring = guaranteed bad time
- **UFW firewall** -- your first line of defense, blocking all unnecessary inbound traffic
- **Docker bypasses UFW** -- the critical gotcha that catches everyone; support containers must use `127.0.0.1:` in port bindings
- **Native apps respect UFW** -- OpenClaw runs natively, so the firewall works as expected for it
- **OpenClaw SecretRef pattern** -- file-based secrets via `openclaw.json` config: `{ "source": "file", "id": "/path/to/secret" }`
- **Docker secrets for support services** -- compose-level secrets or env files for cloudflared, Uptime Kuma, etc.
- **Why .env files leak** -- docker inspect, /proc filesystem, child processes, logs, shell history
- **Automatic security updates** -- patching vulnerabilities before attackers exploit them
- **File permissions** -- why `chmod 600` is your new best friend

### Prerequisites

You should have completed Modules 0-6. You need a running VPS with SSH access, a dedicated `openclaw` user, Docker installed for support services, and OpenClaw installed natively on the VPS.

> **Self-check:** Can you SSH into your server as the `openclaw` user, run `openclaw gateway status` and see your bot running, and run `docker ps` to see any support containers? You're ready.

### Builds On

- **Module 02: Your Computer in the Sky** -- you have a VPS with a static IP (which means it's findable)
- **Module 03: SSH and Linux Basics** -- you created a non-root user and understand permissions
- **Module 04: Containers** -- you know about port mapping, which is directly relevant to open ports
- **Module 06: GitHub Actions Deploy** -- your bot is running, but without security hardening

### What's Next

In **Module 8: Zero Open Ports -- Cloudflare Tunnel**, we'll make your server completely invisible to the internet. The firewall you set up here is good, but a tunnel is better -- zero inbound ports, period. Together, these two modules eliminate two-thirds of the lethal trifecta in a single afternoon.

# OpenClaw Security Checklist

Track your progress through the course. Check off each item as you complete it.
Come back to this after every module and update it.

---

## Firewall and Network

- [ ] UFW enabled with default deny incoming
- [ ] SSH allowed only from your IP address
- [ ] No ports 80/443 open to the internet
- [ ] Cloudflare Tunnel running as Docker container
- [ ] Tunnel configured with catch-all 404 rule for unexpected requests

## Secrets Management

- [ ] API keys NOT stored in plain `.env` files
- [ ] Docker Secrets (or equivalent) implemented
- [ ] All sensitive files have `chmod 600` permissions
- [ ] No secrets committed to git (check with `git log` if applicable)
- [ ] Secret vs non-secret config separated

## Access Control

- [ ] Running as dedicated `openclaw` user (not root)
- [ ] `openclaw` user in `docker` group (no need for sudo with Docker)
- [ ] Phone number allowlist configured (only your number + trusted contacts)
- [ ] GitHub tokens use fine-grained permissions (not classic tokens)
- [ ] GitHub tokens scoped to specific repos only
- [ ] Gmail access uses `readonly` scope only
- [ ] Dedicated Gmail account (not your personal one)

## Webhook Security

- [ ] Meta webhook signature verification (X-Hub-Signature-256) enabled
- [ ] Webhook URL is not publicly discoverable

## System Updates

- [ ] Automatic OS security updates enabled (unattended-upgrades)
- [ ] Checked for pending updates: `sudo apt update && sudo apt list --upgradable`

## Monitoring

- [ ] Health check script or monitoring service configured
- [ ] Cron job running health checks every 5 minutes (or Uptime Kuma equivalent)
- [ ] Push notifications set up for outages (Telegram, email, or Discord)
- [ ] Resource monitoring in place (CPU, RAM, disk alerts)

## Kill Switch

- [ ] Secret kill URL generated and bookmarked on phone
- [ ] Kill URL tested (tap it, verify OpenClaw stops)
- [ ] VPS provider mobile app installed on phone
- [ ] Full kill + revive cycle tested
- [ ] Escalation playbook printed or saved somewhere accessible offline

## AI-Specific Security

- [ ] Prompt injection risks understood for each integration
- [ ] Gmail filters restrict which senders reach the AI
- [ ] OpenClaw not configured to follow links from email content
- [ ] Write access tokens used only where write access is truly needed

---

## Quick Status

After each module, update this summary:

| Trifecta Leg     | Status       | Covered In    |
|------------------|--------------|---------------|
| Open Ports       | [ ] Hardened | Modules 5, 7  |
| Exposed Secrets  | [ ] Hardened | Module 6      |
| No Monitoring    | [ ] Hardened | Module 10     |

**Last reviewed:** _______________

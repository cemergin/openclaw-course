# OpenClaw Security Checklist -- COMPLETED

This is the fully completed version showing all items checked off
and which module covers each one.

---

## Firewall and Network

- [x] UFW enabled with default deny incoming -- **Module 5**
- [x] SSH allowed only from your IP address -- **Module 5**
- [x] No ports 80/443 open to the internet -- **Module 5** (default deny)
- [x] Cloudflare Tunnel running as Docker container -- **Module 7**
- [x] Tunnel configured with catch-all 404 rule for unexpected requests -- **Module 7**

## Secrets Management

- [x] API keys NOT stored in plain `.env` files -- **Module 6** (Docker Secrets)
- [x] Docker Secrets (or equivalent) implemented -- **Module 6** (files mounted at /run/secrets/)
- [x] All sensitive files have `chmod 600` permissions -- **Module 6** (also checked in Module 5 exercise)
- [x] No secrets committed to git -- **Module 6** (verified with git log, .gitignore in place)
- [x] Secret vs non-secret config separated -- **Module 6** (config in YAML, secrets in /run/secrets/)

## Access Control

- [x] Running as dedicated `openclaw` user (not root) -- **Module 3** (verified in Module 5)
- [x] `openclaw` user in `docker` group -- **Module 3** (verified in Module 5)
- [x] Phone number allowlist configured -- **Module 8** (only your number + trusted contacts)
- [x] GitHub tokens use fine-grained permissions (not classic tokens) -- **Module 12**
- [x] GitHub tokens scoped to specific repos only -- **Module 12** (read-only + read-write separate tokens)
- [x] Gmail access uses `readonly` scope only -- **Module 12** (gmail.readonly OAuth scope)
- [x] Dedicated Gmail account (not your personal one) -- **Module 12** (throwaway for newsletters)

## Webhook Security

- [x] Meta webhook signature verification (X-Hub-Signature-256) enabled -- **Module 8** (OpenClaw validates automatically, verified in config)
- [x] Webhook URL is not publicly discoverable -- **Module 7** (routed through Cloudflare Tunnel)

## System Updates

- [x] Automatic OS security updates enabled -- **Module 5** (unattended-upgrades configured)
- [x] Checked for pending updates -- **Module 5** (part of exercise)

## Monitoring

- [x] Health check script or monitoring service configured -- **Module 10** (Uptime Kuma + healthcheck.sh)
- [x] Cron job running health checks every 5 minutes -- **Module 10** (crontab entry)
- [x] Push notifications set up for outages -- **Module 10** (Telegram/email alerts via Uptime Kuma)
- [x] Resource monitoring in place -- **Module 10** (CPU, RAM, disk thresholds in healthcheck.sh)

## Kill Switch

- [x] Secret kill URL generated and bookmarked on phone -- **Module 11** (kill-{random hex})
- [x] Kill URL tested -- **Module 11** (tap bookmark, verify OpenClaw stops)
- [x] VPS provider mobile app installed on phone -- **Module 11** (Lightsail/Hetzner/DO app)
- [x] Full kill + revive cycle tested -- **Module 11** (kill via URL, revive via docker compose up -d)
- [x] Escalation playbook printed/saved -- **Module 11** (URL > WhatsApp > SSH > provider app)

## AI-Specific Security

- [x] Prompt injection risks understood for each integration -- **Module 5** (concept), **Module 12** (applied)
- [x] Gmail filters restrict which senders reach the AI -- **Module 12** (only approved newsletter domains)
- [x] OpenClaw not configured to follow links from email content -- **Module 12** (browser access scoped)
- [x] Write access tokens used only where truly needed -- **Module 12** (read-only defaults, write only for push repos)

---

## Quick Status

| Trifecta Leg     | Status        | Covered In    |
|------------------|---------------|---------------|
| Open Ports       | [x] Hardened  | Modules 5, 7  |
| Exposed Secrets  | [x] Hardened  | Module 6      |
| No Monitoring    | [x] Hardened  | Module 10     |

**Last reviewed:** Course completion

---

## Module-by-Module Security Progression

| Module | Security Items Completed |
|--------|------------------------|
| 3      | Non-root user, SSH keys, file permissions basics |
| 5      | UFW firewall, auto-updates, security mental model |
| 6      | Docker Secrets, chmod 600, no secrets in git |
| 7      | Cloudflare Tunnel, zero open ports, catch-all 404 |
| 8      | Webhook signature verification, phone allowlist |
| 10     | Health checks, Uptime Kuma, push notifications |
| 11     | Kill switch (4 methods), escalation playbook |
| 12     | Scoped tokens, Gmail readonly, dedicated accounts |

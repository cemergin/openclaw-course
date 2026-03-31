# OpenClaw Course Progress

## Student: cemergin
## Started: 2026-03-25
## Course Version: 2.2 (hybrid: native OpenClaw + Docker support services)

---

## Module 0: Speed Run
- **Status:** Skipped (taking full course path)

## Module 1: What Are AI Agents?
- **Status:** Skipped (prior knowledge)

## Module 2: Docker on Your Machine
- **Status:** NOT STARTED
- Prior Docker knowledge from v1 Module 4 (nginx + whoami exercise, SearXNG challenge)
- Key pattern learned: `127.0.0.1:` port binding for security

## Module 3: OpenClaw in Docker + Config-as-Code
- **Status:** NOT STARTED
- This is the big one: run OpenClaw locally, build config-as-code repo
- Need to test: Does ghcr.io/openclaw/openclaw:latest work?
- Need to test: Two-service pattern (gateway + cli)
- Need to test: openclaw.json with SecretRef, SOUL.md personality

## Module 4: Your Computer in the Sky
- **Status:** PARTIAL (from v1 Modules 2+3)
- Instance: AWS Lightsail, us-east-1
- Static IP: 50.17.15.105
- SSH config shortcut: `ssh openclaw` works
- SSH key: ~/.ssh/openclaw
- **NOTE:** v2.2 uses $5/mo 1GB instance (native OpenClaw, not Docker)
- Current instance is $12/mo (2GB) — could downgrade to save $7/mo

## Module 5: Git Push to Deploy
- **Status:** NOT STARTED
- Config-as-code deploy: git pull + copy config + openclaw gateway restart + docker compose up
- GitHub Actions with appleboy/ssh-action

## Module 6: Verify on Instance
- **Status:** NOT STARTED
- Native OpenClaw: openclaw doctor, openclaw gateway start
- No docker exec — direct CLI
- THE BIG MOMENT: close laptop, send Telegram, bot still responds

## Module 7: Security + Secrets
- **Status:** PARTIAL (from v1 Module 5)
- UFW: Enabled, deny incoming, allow outgoing, port 22 from anywhere
- Auto-updates: Enabled (unattended-upgrades)
- SecretRef: NOT YET IMPLEMENTED (need to migrate from env vars to file-based)
- Docker support services: Need 127.0.0.1: port binding
- Password auth: Disabled

## Module 8: Cloudflare Tunnel
- **Status:** NOT STARTED
- cloudflared runs in Docker, routes to localhost:18789 (native OpenClaw)

## Module 9: Monitoring + Kill Switch
- **Status:** NOT STARTED
- Uptime Kuma in Docker, kill switch uses openclaw gateway stop/start

## Module 10: Bonus Integrations
- **Status:** NOT STARTED

---

## V2.2 Migration TODO

- [ ] Test OpenClaw Docker image locally (ghcr.io/openclaw/openclaw:latest)
- [ ] Test two-service Docker pattern (gateway + cli)
- [ ] Test openclaw.json config with SecretRef pattern
- [ ] Test SOUL.md personality loading
- [ ] Build config-as-code repo (Module 3)
- [ ] Consider downgrading Lightsail from $12/2GB to $5/1GB
- [ ] Install Node.js + native OpenClaw on VPS
- [ ] Set up GitHub Actions for config-as-code deploy
- [ ] Migrate secrets from env vars to SecretRef files

## Notes
- Docker bypasses UFW via iptables — use 127.0.0.1: on support containers only
- Native OpenClaw respects UFW normally
- Lightsail browser-based SSH is the fallback if locked out
- OpenClaw gateway port: 18789
- Config: ~/.openclaw/openclaw.json (JSON5)
- Personality: ~/.openclaw/workspace/SOUL.md

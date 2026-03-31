# Fast-Forward Course Test

Skip the teaching — just run the checkpoints to verify the course flow works.

## Prerequisites

- Docker Desktop installed and running
- Anthropic API key ready
- Telegram account + phone
- AWS account with payment method
- GitHub account

---

## Phase 1: Local Docker (Modules 2-3)

### 2.1 — Docker works
```bash
docker --version
docker compose version
docker run --rm hello-world
```
**Pass:** All three commands succeed.

### 2.2 — Multi-service compose works
```bash
mkdir -p ~/openclaw-test && cd ~/openclaw-test
cat > docker-compose.yml << 'EOF'
services:
  web:
    image: nginx:alpine
    ports:
      - "127.0.0.1:8080:80"
  whoami:
    image: traefik/whoami
    ports:
      - "127.0.0.1:8081:80"
EOF
docker compose up -d
curl -s http://localhost:8080 | head -5
curl -s http://localhost:8081 | head -5
docker compose down
```
**Pass:** Both services respond.

### 3.1 — OpenClaw container runs
```bash
cd ~/openclaw-test
cat > docker-compose.yml << 'EOF'
services:
  openclaw-gateway:
    image: ghcr.io/openclaw/openclaw:latest
    container_name: openclaw-gateway
    restart: unless-stopped
    ports:
      - "127.0.0.1:18789:18789"
    volumes:
      - openclaw-data:/home/node/.openclaw

  openclaw-cli:
    image: ghcr.io/openclaw/openclaw:latest
    network_mode: "service:openclaw-gateway"
    volumes:
      - openclaw-data:/home/node/.openclaw
    profiles: ["cli"]

volumes:
  openclaw-data:
EOF
docker compose up -d
docker compose logs openclaw-gateway --tail 20
```
**Pass:** Gateway starts. Logs show OpenClaw gateway on port 18789.

### 3.2 — OpenClaw onboarding works
```bash
docker compose run --rm openclaw-cli openclaw onboard
# Follow interactive prompts:
# - Enter Anthropic API key
# - Select model
# - Skip other integrations for now
```
**Pass:** Onboarding completes. Config saved in volume.

### 3.3 — Terminal test (Anthropic token works)
```bash
docker compose run --rm openclaw-cli openclaw chat
# Type a test message, get a response
```
**Pass:** Claude responds to a prompt.

### 3.4 — Telegram integration
```bash
# 1. Talk to @BotFather on Telegram, create bot, copy token
# 2. Add channel:
docker compose run --rm openclaw-cli openclaw channels add --channel telegram --token <YOUR_BOT_TOKEN>
# 3. Send a message to your bot on Telegram
```
**Pass:** Bot responds on Telegram.

### 3.5 — Config-as-code repo
```bash
mkdir -p ~/my-openclaw/{config,workspace/skills,secrets}
# Copy config from Docker volume:
docker compose run --rm openclaw-cli cat /home/node/.openclaw/openclaw.json > ~/my-openclaw/config/openclaw.json
# Create personality:
echo "You are a helpful, witty personal assistant." > ~/my-openclaw/workspace/SOUL.md
echo "name: My Bot" > ~/my-openclaw/workspace/IDENTITY.md
# Create .gitignore:
echo -e "secrets/\n.env\n*.secret" > ~/my-openclaw/.gitignore
# Create placeholder compose for support services:
echo "services: {}" > ~/my-openclaw/docker-compose.yml
# Init git:
cd ~/my-openclaw && git init && git add -A && git commit -m "Initial config-as-code"
```
**Pass:** Git repo with config, personality, and .gitignore.

---

## Phase 2: Deploy to Instance (Modules 4-6)

### 4.1 — VPS provisioned
```bash
# Via AWS Console: Lightsail → Create instance
# - Ubuntu 22.04
# - 1GB RAM ($5/mo plan) — first 3 months free
# - Region: us-east-1 (or closest)
# - Attach static IP

# Test SSH:
ssh openclaw "echo 'connected'"
```
**Pass:** SSH connection works.

### 4.2 — Node.js + OpenClaw on VPS
```bash
ssh openclaw << 'REMOTE'
curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
sudo apt install -y nodejs
npm i -g openclaw
openclaw --version
REMOTE
```
**Pass:** OpenClaw installed natively.

### 4.3 — Docker on VPS (for support services)
```bash
ssh openclaw << 'REMOTE'
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
REMOTE

# Reconnect (group change needs new session)
ssh openclaw "docker --version && docker compose version"
```
**Pass:** Docker installed for support services.

### 5.1 — GitHub repo created
```bash
cd ~/my-openclaw
gh repo create openclaw-deploy --private --source=. --push
```
**Pass:** Private repo created and pushed.

### 5.2 — GitHub Actions deploy works
```bash
mkdir -p .github/workflows
cat > .github/workflows/deploy.yml << 'EOF'
name: Deploy to VPS
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Deploy via SSH
        uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.VPS_HOST }}
          username: ${{ secrets.VPS_USER }}
          key: ${{ secrets.VPS_SSH_KEY }}
          script: |
            cd ~/openclaw-deploy || git clone ${{ github.event.repository.ssh_url }} ~/openclaw-deploy
            cd ~/openclaw-deploy && git pull origin main
            cp config/openclaw.json ~/.openclaw/openclaw.json
            cp -r workspace/* ~/.openclaw/workspace/
            npm update -g openclaw
            openclaw gateway restart || openclaw gateway start
            docker compose up -d
EOF
git add .github/
git commit -m "Add GitHub Actions deploy workflow"
git push

# Set secrets in GitHub:
# gh secret set VPS_HOST --body "<static-ip>"
# gh secret set VPS_USER --body "ubuntu"
# gh secret set VPS_SSH_KEY < ~/.ssh/openclaw
```
**Pass:** Push triggers action, action SSHs to VPS and deploys.

### 6.1 — OpenClaw runs natively on VPS
```bash
ssh openclaw "openclaw gateway status"
ssh openclaw "openclaw doctor"
```
**Pass:** Gateway is running, doctor shows all green.

### 6.2 — Telegram works from VPS
```bash
# Send a message to your bot on Telegram
# Close your laptop lid
# Send another message — bot still responds
```
**Pass:** Telegram bot works from the VPS 24/7.

---

## Phase 3: Production Hardening (Modules 7-9)

### 7.1 — Firewall
```bash
ssh openclaw << 'REMOTE'
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22
sudo ufw --force enable
sudo ufw status
REMOTE
```
**Pass:** UFW active, only port 22 open.

### 7.2 — SecretRef secrets
```bash
ssh openclaw << 'REMOTE'
mkdir -p ~/openclaw-deploy/secrets
chmod 700 ~/openclaw-deploy/secrets
# Move API keys to secret files
echo "sk-ant-xxxxx" > ~/openclaw-deploy/secrets/anthropic_api_key
chmod 600 ~/openclaw-deploy/secrets/anthropic_api_key
REMOTE

# Update openclaw.json to use SecretRef:
# { "source": "file", "id": "/home/ubuntu/openclaw-deploy/secrets/anthropic_api_key" }
# Push config change, let GitHub Actions deploy
```
**Pass:** Secrets in files with 600 permissions, referenced via SecretRef.

### 8.1 — Cloudflare Tunnel
```bash
# 1. Cloudflare dashboard: create tunnel, get token
# 2. Add cloudflared to docker-compose.yml (support services)
# 3. Push and deploy
# 4. Verify tunnel routes to localhost:18789 (native OpenClaw)
curl -s https://openclaw.yourdomain.com/healthz
```
**Pass:** Tunnel routes traffic to native OpenClaw. No ports open except SSH.

### 9.1 — Uptime Kuma
```bash
# Add to docker-compose.yml, route via tunnel subdomain
# Push and deploy
```
**Pass:** Uptime Kuma dashboard accessible via tunnel subdomain.

### 9.2 — Kill switch
```bash
# Kill uses native command:
ssh openclaw "openclaw gateway stop"
# Verify bot stopped (send Telegram message, no response)

# Revive:
ssh openclaw "openclaw gateway start"
# Verify bot responds again
```
**Pass:** Kill stops OpenClaw, revive brings it back.

---

## Summary Checklist

| # | Checkpoint | Status |
|---|-----------|--------|
| 2.1 | Docker works locally | ☐ |
| 2.2 | Multi-service compose | ☐ |
| 3.1 | OpenClaw container starts | ☐ |
| 3.2 | Onboarding completes | ☐ |
| 3.3 | Terminal prompt works | ☐ |
| 3.4 | Telegram works locally | ☐ |
| 3.5 | Config-as-code repo | ☐ |
| 4.1 | VPS provisioned + SSH | ☐ |
| 4.2 | Node.js + OpenClaw native | ☐ |
| 4.3 | Docker on VPS (support) | ☐ |
| 5.1 | GitHub repo | ☐ |
| 5.2 | GitHub Actions deploy | ☐ |
| 6.1 | OpenClaw native on VPS | ☐ |
| 6.2 | Telegram from VPS 24/7 | ☐ |
| 7.1 | Firewall | ☐ |
| 7.2 | SecretRef secrets | ☐ |
| 8.1 | Cloudflare Tunnel | ☐ |
| 9.1 | Uptime Kuma | ☐ |
| 9.2 | Kill switch | ☐ |

## Known Unknowns (test these first)

1. **OpenClaw Docker image** — Does `ghcr.io/openclaw/openclaw:latest` exist and work? Two-service pattern?
2. **Native install on 1GB** — Does `npm i -g openclaw && openclaw onboard` work on 1GB RAM?
3. **SecretRef** — Does `{ source: "file", id: "/path" }` work in openclaw.json for API keys and Telegram tokens?
4. **Config copy** — Does copying openclaw.json to ~/.openclaw/ and restarting gateway pick up changes?
5. **Tunnel routing** — Does cloudflared in Docker route correctly to localhost:18789 (native gateway)?

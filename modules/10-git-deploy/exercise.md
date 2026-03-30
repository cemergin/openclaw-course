# Exercise: Set Up Git-Based Deployment

## What We're Doing

You're going to move your OpenClaw configuration into a private GitHub repo, set up a `.gitignore` that protects secrets, create example secret templates, and build a deploy script. By the end, you'll edit files locally and deploy with a single command.

## Prerequisites

- A working OpenClaw stack from Module 9
- A GitHub account
- Git installed on your VPS (`sudo apt install git -y` if not)

---

## Step 1: Create the GitHub Repo

1. Go to github.com → New repository
2. Name: `openclaw-config` (or your preference)
3. **Private** (not public)
4. Don't initialize with README (we'll push existing files)
5. Click Create

## Step 2: Generate a Fine-Grained Token

1. GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens
2. Generate new token:
   - **Name:** `openclaw-deploy`
   - **Expiration:** 90 days
   - **Repository access:** Only select repositories → `openclaw-config`
   - **Permissions:** Contents → Read-only
3. Copy the token — you'll only see it once

**Store this token as a secret on your VPS:**

```bash
echo -n "github_pat_xxxxx" > ~/openclaw/secrets/github_token
chmod 600 ~/openclaw/secrets/github_token
```

## Step 3: Create .gitignore FIRST

On your VPS:

```bash
cd ~/openclaw
cat > .gitignore << 'EOF'
secrets/
!secrets/*.example
*.log
.env.local
EOF
```

This MUST exist before you `git add` anything.

## Step 4: Create Secret Example Files

These are documentation — they tell you (or future-you) what secrets are needed without containing actual values:

```bash
echo "# Anthropic API key from https://console.anthropic.com/settings/keys" > secrets/anthropic_api_key.example
echo "# WhatsApp permanent access token from Meta Business Settings" > secrets/whatsapp_access_token.example
echo "# WhatsApp App Secret from App Settings > Basic" > secrets/whatsapp_app_secret.example
echo "# Random string you chose for webhook verification" > secrets/whatsapp_verify_token.example
echo "# Cloudflare Tunnel token from Zero Trust dashboard" > secrets/cloudflare_tunnel_token.example
```

## Step 5: Initialize Git and Push

```bash
cd ~/openclaw
git init
git add .

# Verify secrets are NOT staged
git status

# You should NOT see any files from secrets/ (except .example files)
# If you see real secret files, STOP and check your .gitignore

git commit -m "Initial OpenClaw configuration"
git remote add origin https://$(cat secrets/github_token)@github.com/YOURUSERNAME/openclaw-config.git
git push -u origin main
```

**CRITICAL:** Before committing, verify `git status` does NOT show your real secret files. Only `.example` files should appear.

## Step 6: Create the Deploy Script

```bash
cat > ~/openclaw/deploy.sh << 'SCRIPT'
#!/bin/bash
set -e

cd ~/openclaw

echo "Pulling latest configuration..."
git pull origin main

echo "Restarting services..."
docker compose down
docker compose up -d

echo "Checking health..."
docker compose ps

echo "Deploy complete!"
SCRIPT

chmod +x ~/openclaw/deploy.sh
git add deploy.sh
git commit -m "Add deploy script"
git push
```

## Step 7: Test the Workflow

Now test the full cycle:

1. On your **local machine**, clone the repo:
   ```bash
   git clone https://github.com/YOURUSERNAME/openclaw-config.git
   cd openclaw-config
   ```

2. Make a small change (edit a comment in docker-compose.yml or .env)

3. Push it:
   ```bash
   git add .
   git commit -m "Test deploy workflow"
   git push
   ```

4. On your **VPS**, deploy:
   ```bash
   cd ~/openclaw
   ./deploy.sh
   ```

5. Verify your services are running:
   ```bash
   docker compose ps
   ```

If that worked — you just deployed a config change without touching nano.

## What Just Happened?

- Your configuration is version-controlled and recoverable
- Secrets stay on the server, protected by `.gitignore`
- Example files document what secrets are needed
- A deploy script makes updates repeatable and auditable
- `git log` tells you exactly what changed and when

## Try This (Optional)

1. **Disaster recovery test:** On a piece of paper, write down the steps to rebuild your server from scratch using only the GitHub repo + your password manager (where you should store secret values). How long would it take?

2. **Branch and test:** Create a git branch, make a change, deploy it. If it breaks, `git checkout main && ./deploy.sh` rolls back instantly.

3. **Pre-commit hook:** Add a git hook that scans for common secret patterns (API keys, tokens) and blocks the commit if found. Tools like `gitleaks` do this automatically.

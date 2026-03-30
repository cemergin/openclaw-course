# Git Push to Deploy — No More Nano on the Server

## Why This Matters

Let's be honest about what we've been doing. Every time you needed to change a Docker Compose file, you:

1. SSH into the server
2. Open nano
3. Carefully type YAML (or paste from your local machine and pray the indentation survives)
4. Save and hope you didn't break anything
5. Run `docker compose up -d` and check the logs

This works. It's also how you end up debugging YAML parsing errors at 11pm because a tab snuck in where a space should be.

More importantly, if your server dies tomorrow -- disk failure, provider outage, you accidentally `rm -rf` the wrong directory -- can you rebuild it? From memory? Every file, every config value, every compose service?

Probably not. And that's the real problem.

## Infrastructure as Code

The fix is simple: put your configuration files in a git repo.

```
BEFORE (fragile):
  Your server's ~/openclaw/ directory
    └── The only copy of your config
        If this dies, you start over.

AFTER (resilient):
  GitHub repo (private)
    └── docker-compose.yml
    └── entrypoint-wrapper.sh
    └── .env (non-secret config only)
    └── .gitignore (blocks secrets/)

  Your server's ~/openclaw/ directory
    └── Cloned from the repo
    └── secrets/ (local only, never in git)
        If this dies, clone the repo + recreate secrets.
```

The principle: **config in git, secrets on the server.** Your compose files, scripts, and non-secret configuration are version-controlled. Your API keys and tokens stay in `~/openclaw/secrets/` and never touch git.

## What Goes in the Repo (And What Doesn't)

| File | In Git? | Why |
|---|---|---|
| `docker-compose.yml` | Yes | Core infrastructure definition |
| `entrypoint-wrapper.sh` | Yes | Script, not a secret |
| `.env` (non-secret config) | Yes | Phone number IDs, log levels, URLs |
| `.gitignore` | Yes | Protects secrets from accidental commits |
| `secrets/` | **NO** | API keys, tokens -- never in git |
| `secrets/*.example` | Yes | Templates showing what secrets are needed (no values) |

The `.gitignore` is your safety net:

```gitignore
# Never commit secrets
secrets/
!secrets/*.example

# Docker runtime files
*.log
```

And the example files serve as documentation:

```bash
# secrets/anthropic_api_key.example
# Your Anthropic API key
# Get it from: https://console.anthropic.com/settings/keys
# Copy this file to 'anthropic_api_key' and paste your real key
YOUR_KEY_HERE
```

When you rebuild the server, these examples tell you exactly what secrets you need to create.

## Setting Up the Repo

### Step 1: Create a Private GitHub Repo

Go to github.com and create a new **private** repository called `openclaw-config` (or whatever you prefer). Private is important -- even though secrets aren't in the repo, your compose files reveal your infrastructure architecture. No need to share that.

### Step 2: Generate a Fine-Grained GitHub Token

We're applying least privilege here (Module 5 principles):

1. Go to GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens
2. Create a new token with:
   - **Repository access:** Only select repositories → `openclaw-config`
   - **Permissions:** Contents → Read-only
   - **Expiration:** 90 days (set a calendar reminder to rotate it)

Read-only. One repo. Short expiration. That's least privilege applied to deployment.

### Step 3: Clone to Your Server

```bash
cd ~
git clone https://YOUR_TOKEN@github.com/yourusername/openclaw-config.git openclaw
```

Or if you already have `~/openclaw`, initialize git in the existing directory:

```bash
cd ~/openclaw
git init
git remote add origin https://YOUR_TOKEN@github.com/yourusername/openclaw-config.git
```

### Step 4: Create .gitignore FIRST

Before committing anything:

```bash
cat > .gitignore << 'EOF'
secrets/
!secrets/*.example
*.log
.env.local
EOF
```

This is your security boundary. Create it before `git add` anything.

### Step 5: Push Your Config

```bash
git add .
git commit -m "Initial OpenClaw configuration"
git push -u origin main
```

## The Deploy Script

Now the fun part. Instead of SSH → nano → save → compose up, you create a simple deploy script:

```bash
#!/bin/bash
# deploy.sh — Pull latest config and restart services

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
```

Put this in the repo too. Now deploying a change is:

1. Edit files on your local machine (with a real editor, not nano)
2. `git push`
3. SSH into server, run `./deploy.sh`

That's it. No nano. No YAML indentation anxiety. And if something breaks, `git log` shows you exactly what changed.

## Advanced: Automated Deploy (Optional)

If you want to skip the "SSH and run deploy.sh" step, you can set up a webhook that triggers the deploy automatically on push. The flow:

```
git push → GitHub webhook → Cloudflare Tunnel → deploy endpoint → runs deploy.sh
```

This is real CI/CD -- but it requires careful security consideration (the deploy endpoint needs authentication). We'll leave this as an optional exercise. For most personal setups, "SSH and run deploy.sh" is the right balance of convenience and control.

## What You Just Learned

1. **Infrastructure as Code** -- config files belong in git, not just on the server
2. **Secrets stay local** -- `.gitignore` is your security boundary
3. **Fine-grained tokens** -- least privilege applied to GitHub access
4. **Example files** -- documentation for what secrets are needed
5. **Deploy scripts** -- repeatable, auditable deployments
6. **Disaster recovery** -- clone repo + create secrets = back in business

The biggest win isn't convenience (though that's nice). It's **recoverability**. Your server is now rebuildable. That's the difference between "my server died and I lost everything" and "my server died and I was back up in 30 minutes."

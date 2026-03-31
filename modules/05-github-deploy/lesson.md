# Git Push to Deploy

## Config-as-Code Deployment with GitHub Actions

---

## Why This Matters

Let's be honest about what you'd be doing without this module. Every time you want to tweak your agent's personality, you'd:

1. SSH into the server
2. Open nano
3. Carefully edit SOUL.md (and pray you don't mess up the formatting)
4. Manually restart the OpenClaw gateway
5. Hope you didn't break anything

This works. It's also how you end up debugging things at 11pm because you forgot to copy a file.

More importantly: if your server dies tomorrow -- disk failure, provider outage, you accidentally `rm -rf` the wrong directory -- can you rebuild it? From memory? Every config value, every personality tweak, every custom skill?

Probably not. And that's the real problem.

## Config-as-Code: Your Repo IS the Deployment

Here's the beautiful part: **you already built the deployment repo in Module 3.** Your config-as-code repo isn't just a backup -- it's the source of truth. Everything on the server is a copy of what's in git.

```
YOUR CONFIG-AS-CODE REPO (from Module 3):
├── config/
│   └── openclaw.json          ← OpenClaw configuration (JSON5)
├── workspace/
│   ├── SOUL.md                ← Your agent's personality
│   ├── IDENTITY.md            ← Identity and boundaries
│   └── skills/                ← Custom capabilities
├── docker-compose.yml         ← Support services (tunnel, monitoring, kill switch)
├── .github/
│   └── workflows/
│       └── deploy.yml         ← The new part: automated deployment
└── .gitignore                 ← Security boundary (excludes secrets/)
```

The GitHub Actions workflow is the only new file. Everything else is already there.

## The .gitignore: Your Security Boundary

Your repo already has a `.gitignore` from Module 3, but let's make sure it's airtight. This file is the line between "configuration that belongs in version control" and "secrets that would ruin your day if they leaked."

| File/Directory | In Git? | Why |
|---|---|---|
| `config/openclaw.json` | Yes | Core agent configuration |
| `workspace/SOUL.md` | Yes | Agent personality |
| `workspace/IDENTITY.md` | Yes | Agent identity and boundaries |
| `workspace/skills/` | Yes | Custom capabilities |
| `docker-compose.yml` | Yes | Support service definitions |
| `.github/workflows/deploy.yml` | Yes | Deployment automation |
| `.gitignore` | Yes | Protects secrets from accidental commits |
| `secrets/` | **NO** | API keys, tokens -- never in git |
| `.env` | **NO** | Environment variables with sensitive values |

The secrets (your Anthropic API key, Telegram token, etc.) are stored directly on the server or in GitHub Secrets. They never touch git.

## GitHub Actions: Your Robot Assistant

GitHub Actions is a CI/CD service built into GitHub. When you push code, GitHub Actions can automatically run commands -- build, test, deploy, whatever you want.

Here's how our deploy workflow works:

```
You edit SOUL.md locally
        |
        v
You push to GitHub (git push)
        |
        v
GitHub Actions triggers
        |
        v
The workflow SSHes into your VPS
        |
        v
It runs commands on your server:
  1. git pull (get latest files)
  2. Copy config/openclaw.json → ~/.openclaw/openclaw.json
  3. Copy workspace/* → ~/.openclaw/workspace/
  4. npm update -g openclaw (update if needed)
  5. openclaw gateway restart
  6. docker compose up -d (support services)
        |
        v
Your agent's personality is updated. Done.
```

### The Six Deploy Steps

Let's talk about what each step actually does:

**1. `git pull`** -- Fetches the latest files from your repo onto the VPS. On first run, it clones instead of pulling.

**2. Copy `config/openclaw.json` to `~/.openclaw/openclaw.json`** -- OpenClaw reads its configuration from `~/.openclaw/openclaw.json` (JSON5 format). Your repo stores it in `config/` for clean organization; the deploy script puts it where OpenClaw expects it.

**3. Copy `workspace/*` to `~/.openclaw/workspace/`** -- Your SOUL.md, IDENTITY.md, and skills directory get placed where the OpenClaw gateway reads them. This is where the magic happens -- change SOUL.md locally, push, and your agent's entire personality updates.

**4. `npm update -g openclaw`** -- Checks for a newer version of OpenClaw and installs it if available. This keeps your agent up to date without manual intervention.

**5. `openclaw gateway restart`** -- Restarts the OpenClaw gateway process so it picks up the new configuration and workspace files. If the gateway isn't running yet, the verify module (Module 6) handles the first start.

**6. `docker compose up -d`** -- Starts or updates the support services (Cloudflare Tunnel, Uptime Kuma, kill switch). The `-d` runs them in the background.

### The Three Pieces of a Workflow

Every GitHub Actions workflow has three parts:

**1. Triggers** -- When should this run?

```yaml
on:
  push:
    branches: [main]
```

This says: "Run this workflow every time someone pushes to the `main` branch."

**2. Jobs** -- What work needs to happen?

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
```

A job runs on a fresh virtual machine (called a "runner") that GitHub provides for free. `ubuntu-latest` means it's a Linux box.

**3. Steps** -- What specific commands should run?

Each step either runs a shell command or uses a pre-built action. We use `appleboy/ssh-action` to SSH into the VPS and run our deploy script.

### appleboy/ssh-action: The SSH Bridge

`appleboy/ssh-action` is a popular open-source GitHub Action that does one thing: SSH into a server and run commands. It handles the connection, authentication, and cleanup. You just provide the credentials and the script.

The credentials come from **GitHub Secrets** -- encrypted variables that only the workflow can read. Not you, not collaborators, not even GitHub support. They're encrypted at rest and only decrypted during workflow execution.

## GitHub Secrets: The Vault

You'll store three secrets in your GitHub repo:

| Secret Name | Value | Where it comes from |
|---|---|---|
| `VPS_HOST` | Your static IP address | Module 4, Step 27 |
| `VPS_USER` | `deploy` | Module 4, Step 48 |
| `VPS_SSH_KEY` | Your private SSH key contents | The contents of `~/.ssh/openclaw` |

These are set in GitHub under Settings > Secrets and variables > Actions. Once set, they're referenced in workflows as `${{ secrets.SECRET_NAME }}`.

> **Important:** The `VPS_SSH_KEY` is the full contents of your private key file -- including the `-----BEGIN OPENSSH PRIVATE KEY-----` and `-----END OPENSSH PRIVATE KEY-----` lines. Copy the entire thing.

## The Magic Moment

Here's the real payoff of this setup. Say you want your AI agent to be more casual. You:

1. Open `workspace/SOUL.md` in your favorite editor
2. Add a line: "Keep responses short and casual. Use humor when appropriate."
3. Save the file
4. Run `git add . && git commit -m "Make agent more casual" && git push`
5. Wait 30-60 seconds
6. Send a message to your bot on Telegram
7. The response has the new personality

You didn't SSH into anything. You didn't edit files on the server. You didn't restart any services manually. You pushed to git, and your agent updated itself. That's config-as-code deployment.

## Deploy Keys: Read-Only Repo Access

Since your repo is private (it should be!), your VPS needs a way to pull from it. We use a **deploy key** -- an SSH key that gives read-only access to exactly one repo.

Why not a personal access token? Deploy keys follow the principle of least privilege:
- Scoped to one repo (not your entire GitHub account)
- Read-only (can't push, delete, or modify)
- Easy to revoke without affecting other services

## What We Just Learned

1. **Config-as-code** -- your Module 3 repo IS the deployment repo
2. **`.gitignore` is your security boundary** -- secrets/ never touches git
3. **GitHub Actions** -- automated workflows triggered by git push
4. **The deploy flow** -- pull, copy configs, update OpenClaw, restart gateway, start support services
5. **appleboy/ssh-action** -- SSHes into your VPS and runs commands
6. **GitHub Secrets** -- encrypted storage for SSH keys and server details
7. **Deploy keys** -- read-only repo access for your server
8. **The payoff** -- edit SOUL.md locally, push, personality changes deploy automatically

The biggest win isn't convenience. It's **recoverability**. Your server configuration now lives in git. If your VPS dies, you spin up a new one, set the secrets, push, and you're back in business.

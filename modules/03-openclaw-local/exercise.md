# Exercise 3: OpenClaw Running + Config-as-Code Repo

## What We're Doing

This is a two-part exercise. First, we get OpenClaw running in Docker with Telegram (similar to the Speed Run, but properly). Second -- and this is the important part -- we build the config-as-code repository that defines your entire bot. This repo carries through every remaining module in the course.

Estimated time: ~2 hours.

## Prerequisites

- Docker installed and running (from Module 2)
- An **Anthropic API key** -- get one at [console.anthropic.com](https://console.anthropic.com). Add a few dollars of credit. Typical cost: $1-5/month.
- A **Telegram account** -- install Telegram on your phone if you haven't

---

# PART 1: Get OpenClaw Running

If you already have OpenClaw running from the Speed Run (Module 0), you can skip to Part 2. But if you want a clean start, follow along.

## Step 1: Create the Docker Compose File

**1. Create a project directory**

```bash
mkdir -p ~/openclaw
cd ~/openclaw
```

**2. Create the `docker-compose.yml`**

You can copy the starter file from `starter/docker-compose.yml` in this module, or create it yourself:

```yaml
services:
  openclaw-gateway:
    image: ghcr.io/openclaw/openclaw:latest
    container_name: openclaw-gateway
    restart: unless-stopped
    ports:
      - "18789:18789"
    volumes:
      - openclaw-data:/home/node/.openclaw

  openclaw-cli:
    image: ghcr.io/openclaw/openclaw:latest
    container_name: openclaw-cli
    volumes:
      - openclaw-data:/home/node/.openclaw
    profiles:
      - cli

volumes:
  openclaw-data:
```

Two services, one volume. The gateway runs always; the CLI runs on demand.

**3. Pull and start the gateway**

```bash
cd ~/openclaw
docker compose up -d
```

**4. Verify it's running**

```bash
docker compose ps
```

You should see `openclaw-gateway` with status "Up."

```bash
docker compose logs openclaw-gateway
```

Look for startup messages. It might mention it needs configuration -- that's expected.

## Step 2: Run the Onboarding

**5. Run the onboarding wizard**

```bash
docker compose run --rm openclaw-cli openclaw onboard
```

The wizard will ask you:

- **AI Provider:** Choose `anthropic` (for Claude)
- **API Key:** Paste your Anthropic API key (starts with `sk-ant-...`)
- **Model:** The default (Claude Sonnet) is perfect for now
- Follow any additional prompts

> **What's happening?** The CLI service starts, runs the onboarding command, writes the config to `/home/node/.openclaw/openclaw.json` on the shared volume, and exits. The `--rm` flag removes the CLI container after it's done.

**6. Restart the gateway to pick up the new config**

```bash
docker compose restart openclaw-gateway
```

**7. Check gateway status**

```bash
docker compose run --rm openclaw-cli openclaw gateway status
```

You should see the gateway is running and connected to your AI provider.

## Step 3: Create Your Telegram Bot

**8. Open Telegram and find @BotFather**

Search for `@BotFather` in Telegram. It's the official bot for creating bots. Blue checkmark.

**9. Create a new bot**

Send `/newbot` to BotFather. It asks:

- **A display name** for your bot (e.g., "My AI Agent" or "Atlas")
- **A username** for your bot -- must end in `bot` (e.g., `atlas_personal_bot`)

BotFather responds with your bot's **token**. It looks like:

```
7123456789:AAH-some-long-string-of-characters-here
```

**Copy this token.** You'll need it next.

> **Important:** This token is like a password. Anyone who has it can control your bot. Don't share it publicly.

## Step 4: Connect Telegram to OpenClaw

**10. Add the Telegram channel**

```bash
docker compose run --rm openclaw-cli openclaw channels add telegram
```

It will ask for your Telegram bot token. Paste the token from Step 9.

**11. Restart the gateway**

```bash
docker compose restart openclaw-gateway
```

**12. Check the logs to verify Telegram connected**

```bash
docker compose logs --tail 20 openclaw-gateway
```

Look for a line mentioning Telegram or polling. That means it's listening.

## Step 5: The Moment of Truth

**13. Send your first message**

Open Telegram on your phone. Find your bot by its username. Tap Start. Type something:

> "Hey! Are you alive?"

Wait a few seconds. Your bot should respond. If it does -- congratulations! You have a working AI agent on your phone.

**14. Watch the logs while chatting**

In a separate terminal:

```bash
cd ~/openclaw
docker compose logs -f openclaw-gateway
```

Send messages from Telegram and watch them flow through the system. Press `Ctrl+C` to stop following.

---

# PART 2: Build the Config-as-Code Repository

This is the important part. You're going to create a Git repository that defines your entire bot. This repo is the foundation for everything that follows in the course.

## Step 6: Create the Repository Structure

**15. Create the repo directory**

```bash
mkdir -p ~/my-openclaw
cd ~/my-openclaw
```

**16. Create the directory structure**

```bash
mkdir -p config
mkdir -p workspace/skills
mkdir -p secrets
```

Your tree should look like:

```
my-openclaw/
  config/
  workspace/
    skills/
  secrets/
```

## Step 7: Write the .gitignore

**17. Create `.gitignore`**

This is your security boundary. Everything in `secrets/` stays out of Git. Always.

```bash
cat > .gitignore << 'EOF'
# Secrets -- NEVER commit these
secrets/*
!secrets/.gitkeep

# Environment files
.env
.env.*

# OS junk
.DS_Store
Thumbs.db

# Editor files
*.swp
*.swo
*~
.vscode/
.idea/

# Docker data (if any local volumes)
data/
EOF
```

**18. Create the gitkeep file**

```bash
touch secrets/.gitkeep
```

This ensures the `secrets/` directory exists in Git (but its contents are ignored).

## Step 8: Write openclaw.json

**19. Create `config/openclaw.json`**

This is the main config file. Open your editor and create `config/openclaw.json`:

```json5
{
  // OpenClaw Configuration
  // Secrets use SecretRef -- the actual values come from env vars or files,
  // never from this file. This file is safe to commit to Git.

  // AI Model
  model: {
    provider: "anthropic",
    model: "claude-sonnet-4-20250514",
    // SecretRef: reads from ANTHROPIC_API_KEY environment variable
    apiKey: { source: "env", id: "ANTHROPIC_API_KEY" },
  },

  // Chat Channels
  channels: {
    telegram: {
      enabled: true,
      // SecretRef: reads from TELEGRAM_BOT_TOKEN environment variable
      token: { source: "env", id: "TELEGRAM_BOT_TOKEN" },
      polling: true,  // Long polling (no webhook needed for local)
    },
  },

  // Agent Configuration
  agents: {
    default: {
      // $include reads the file contents inline
      soul: "$include:workspace/SOUL.md",
      identity: "$include:workspace/IDENTITY.md",
      // Load all skills from the skills directory
      skills: ["workspace/skills/*"],
    },
  },
}
```

Take a moment to appreciate what this file does:

- It configures the AI model (Claude Sonnet via Anthropic)
- It sets up Telegram with long polling
- It defines one agent whose personality comes from SOUL.md
- **No secrets are in this file.** API keys and tokens reference environment variables via SecretRef
- This file is 100% safe to commit to Git and even push to a public repo

## Step 9: Write SOUL.md

**20. Create `workspace/SOUL.md`**

This is the fun part. This file defines your bot's personality. Everything you write here shapes how your bot responds to every message.

Open your editor and create `workspace/SOUL.md`. Here's a starting point -- but make it your own:

```markdown
# Soul

You are a thoughtful, slightly witty personal AI assistant.

## Communication Style

- Lead with the answer, then offer to elaborate
- Be concise -- respect the user's time
- Use clear, plain language unless technical depth is requested
- A touch of dry humor is welcome, but never at the expense of being helpful

## Principles

- Honesty first: if you don't know something, say so
- No hallucination: never fabricate facts, citations, or URLs
- Privacy: never share information from one conversation in another
- Proactive: if you notice something the user might want to know, mention it

## Expertise

- You're comfortable with technical topics (programming, devops, systems)
- You can help with writing, brainstorming, analysis, and research
- You're good at explaining complex things simply

## What You Don't Do

- You don't pretend to be human
- You don't give medical, legal, or financial advice (you suggest consulting professionals)
- You don't execute dangerous commands without confirming first
```

**Feel free to go wild here.** Some ideas:

- Make it a pirate ("Arrr, I be a helpful sea-faring assistant...")
- Make it Socratic ("I don't give answers. I ask questions that lead you to the answer.")
- Make it a concise engineer ("No fluff. I give you the answer and the command to run. That's it.")
- Make it warm and encouraging ("Every question is a great question! Let's figure this out together!")

This is your bot. Make it sound like someone you'd enjoy talking to.

## Step 10: Write IDENTITY.md

**21. Create `workspace/IDENTITY.md`**

Short and factual. This tells the agent who it is:

```markdown
# Identity

Name: Atlas
Role: Personal AI assistant
Creator: [Your Name]
Version: 1.0
```

Pick a name you like. "Atlas," "Sage," "Friday," "Ghost," whatever feels right. This name will appear in the agent's self-awareness -- if someone asks "what's your name?" it'll know.

## Step 11: Create docker-compose.yml

**22. Create `docker-compose.yml` in the repo root**

This file is for **support services** -- things like Cloudflare Tunnel, monitoring, and kill switch that we'll add in later modules. For now, it's mostly a placeholder. But having it in the repo from the start keeps the structure clean.

```yaml
# Support services for OpenClaw deployment
# These run alongside the OpenClaw gateway on the server.
#
# Currently empty -- services added in later modules:
#   - Cloudflare Tunnel (Module 8)
#   - Uptime Kuma monitoring (Module 9)
#   - Kill switch (Module 9)

services: {}
```

## Step 12: Initialize Git

**23. Initialize the repository**

```bash
cd ~/my-openclaw
git init
git add .
git status
```

Check the output of `git status`. You should see:

- `config/openclaw.json` -- staged (good, no secrets in it)
- `workspace/SOUL.md` -- staged (your personality)
- `workspace/IDENTITY.md` -- staged (your bot's name)
- `docker-compose.yml` -- staged
- `.gitignore` -- staged
- `secrets/.gitkeep` -- staged

You should **NOT** see any files from `secrets/` (other than `.gitkeep`). If you do, your `.gitignore` isn't working -- fix it before committing.

**24. Make the first commit**

```bash
git commit -m "Initial config-as-code: openclaw.json, SOUL.md, IDENTITY.md"
```

You now have a versioned repository that defines your bot. Every change from here is tracked.

> **We're not pushing to GitHub yet.** That's Module 5 (Git Push to Deploy). For now, the repo lives on your laptop.

## Step 13: Test with Your Config

Now let's verify your handcrafted config actually works.

**25. Create a local secrets file for testing**

```bash
cd ~/my-openclaw
cat > secrets/.env << 'EOF'
ANTHROPIC_API_KEY=sk-ant-your-key-here
TELEGRAM_BOT_TOKEN=123456789:your-token-here
EOF
```

Replace the placeholder values with your actual API key and Telegram token.

**26. Copy your config into the running OpenClaw instance**

For now, we'll manually copy the config files into the Docker volume. Later (Module 5), this happens automatically via `git push`.

```bash
# Copy config into the running container
docker cp ~/my-openclaw/config/openclaw.json openclaw-gateway:/home/node/.openclaw/openclaw.json
docker cp ~/my-openclaw/workspace/SOUL.md openclaw-gateway:/home/node/.openclaw/workspace/SOUL.md
docker cp ~/my-openclaw/workspace/IDENTITY.md openclaw-gateway:/home/node/.openclaw/workspace/IDENTITY.md

# Restart the gateway
cd ~/openclaw
docker compose restart openclaw-gateway
```

> **Note:** The `docker cp` approach is a temporary hack for local testing. When we deploy to a server in Modules 5-6, the deploy script handles this automatically.

**27. Test your personality**

Send a message to your Telegram bot. Does it respond with the personality you defined in SOUL.md? Try asking "What's your name?" -- it should respond with the name from IDENTITY.md.

If the personality isn't right, edit `workspace/SOUL.md`, copy it in again, restart, and iterate. This is the beauty of config-as-code -- tweak, deploy, test. Fast feedback loop.

---

## What You Just Built

Let's take stock:

**Running infrastructure:**
- OpenClaw gateway in Docker (port 18789)
- Telegram connected via long polling
- Claude Sonnet as the AI brain

**Config-as-code repository:**
```
my-openclaw/
  config/
    openclaw.json       # Main config with SecretRef (no secrets!)
  workspace/
    SOUL.md             # Bot personality
    IDENTITY.md         # Bot name and role
    skills/             # Empty for now (challenges will fill this)
  docker-compose.yml    # Support services placeholder
  secrets/              # .gitignored
    .gitkeep
    .env                # Local secrets (NOT in Git)
  .gitignore            # Security boundary
```

**Key principles established:**
- Secrets never go in Git (SecretRef pattern)
- Personality is a file, not a setting (easy to version and diff)
- The repo is the single source of truth for your bot
- Everything is reproducible: clone + secrets = identical bot

**What's still missing:**
- The repo isn't on GitHub yet (Module 5)
- No auto-deploy (Module 5)
- No server -- still running on your laptop (Module 4)
- No security hardening (Module 7)
- No monitoring or kill switch (Module 9)

Every remaining module builds on this repo. You'll add files, add services to docker-compose.yml, and push to deploy. The foundation is solid.

Head to the [challenge](challenge.md) for some fun extensions.

# Exercise: Build Your Bot Tonight

## What We're Doing

We're going from zero to a working Telegram bot powered by Claude, running in Docker on your laptop. Every click, every command -- it's all here. Follow along and you'll have a working AI agent by the time you finish your coffee (or beer, no judgment).

## What You'll Need

- A laptop (Mac, Windows, or Linux)
- A Telegram account on your phone
- A credit card for the Anthropic API (you'll spend pennies tonight)
- About 2 hours of uninterrupted time

---

## Part 1: Install Docker Desktop (~10 minutes)

### Step 1: Download Docker Desktop

If you already have Docker installed, skip to Part 2.

1. Go to [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/)
2. Download the version for your OS:
   - **Mac (Apple Silicon):** the "Mac with Apple chip" button
   - **Mac (Intel):** the "Mac with Intel chip" button
   - **Windows:** the "Windows" button (requires Windows 10/11 with WSL2)
   - **Linux:** follow the instructions for your distro
3. Run the installer and follow the prompts
4. Launch Docker Desktop

> **Windows users:** Docker Desktop requires WSL2 (Windows Subsystem for Linux). The installer will prompt you to enable it if it's not already on. Follow the prompts -- it's a one-time setup.

### Step 2: Verify Docker is Running

Open your terminal (Terminal on Mac, PowerShell on Windows) and run:

```bash
docker --version
```

You should see something like:

```
Docker version 27.x.x, build xxxxxxx
```

Now verify Docker Compose:

```bash
docker compose version
```

You should see:

```
Docker Compose version v2.x.x
```

If both commands work, you're golden. If not, make sure Docker Desktop is actually running (check your system tray/menu bar for the whale icon).

> **What just happened?** You installed a tool that lets you run software in isolated containers. Think of it as a mini virtual machine, but way faster and lighter. OpenClaw will run inside one of these containers.

---

## Part 2: Create Your Project (~5 minutes)

### Step 3: Create a Project Folder

```bash
mkdir -p ~/openclaw-local
cd ~/openclaw-local
```

### Step 4: Create the Docker Compose File

Create a file called `docker-compose.yml` in your project folder. You can use any text editor -- VS Code, nano, vim, whatever you're comfortable with.

```yaml
services:
  openclaw-gateway:
    image: ghcr.io/openclaw/openclaw:latest
    container_name: openclaw-gateway
    restart: unless-stopped
    ports:
      - "18789:18789"
    volumes:
      - openclaw_data:/home/node/.openclaw
    environment:
      - NODE_ENV=production

  openclaw-cli:
    image: ghcr.io/openclaw/openclaw:latest
    container_name: openclaw-cli
    volumes:
      - openclaw_data:/home/node/.openclaw
    profiles:
      - cli

volumes:
  openclaw_data:
```

> **What's this file?** It defines two services from the same OpenClaw image. The **gateway** is the always-running agent -- it handles messages, talks to AI models, manages memory. The **CLI** is an on-demand helper for setup commands. Both share the same data volume at `/home/node/.openclaw` so config written by the CLI is immediately available to the gateway. The `profiles: [cli]` trick means the CLI only runs when you explicitly ask for it.

Save the file.

---

## Part 3: Start OpenClaw (~5 minutes)

### Step 5: Pull and Start OpenClaw

From your project folder, run:

```bash
docker compose up -d
```

The `-d` flag means "detached" -- it runs in the background so you get your terminal back.

You'll see Docker pull the OpenClaw image from GitHub Container Registry (this takes a minute the first time -- it's downloading the software). Then it'll start the gateway container.

Verify it's running:

```bash
docker compose ps
```

You should see something like:

```
NAME               IMAGE                                STATUS          PORTS
openclaw-gateway   ghcr.io/openclaw/openclaw:latest     Up 10 seconds   0.0.0.0:18789->18789/tcp
```

Notice only the gateway is running -- the CLI service stays dormant until you need it.

Check the logs to make sure it started okay:

```bash
docker compose logs openclaw-gateway
```

Look for a message indicating OpenClaw is running. If you see errors, check the troubleshooting section at the end.

> **What just happened?** Docker downloaded the OpenClaw image (a pre-built package of all the software) and started the gateway in a container. OpenClaw is now running on your machine, listening on port 18789. The container runs as the `node` user (uid 1000) and stores all its data at `/home/node/.openclaw`.

---

## Part 4: Get Your Claude API Key (~5 minutes)

OpenClaw needs an AI brain. You'll get an API key from Anthropic (Claude).

### Step 6: Create Your Anthropic Account

1. Go to [console.anthropic.com](https://console.anthropic.com/)
2. Sign up or log in
3. Go to **Settings** --> **API Keys** --> **Create Key**
4. Give it a name like `openclaw-local`
5. Copy the key -- it starts with `sk-ant-...`
6. **Important:** Save this key somewhere safe (a notes app, password manager, whatever). You won't be able to see it again after you close this page.
7. Go to **Plans & Billing** and add a payment method (pay-as-you-go)

### Step 7: Set a Spending Limit

While you're in the billing section:

1. Find **Usage Limits**
2. Set a monthly limit of **$10** (plenty for learning)
3. Set a notification threshold at **$5**

> **How much will this cost?** For personal chat use, expect $1-5/month. Claude charges per token (roughly per word). A typical back-and-forth conversation costs fractions of a cent. You'd have to work really hard to spend $20 in a month.

---

## Part 5: Run OpenClaw Onboarding (~10 minutes)

### Step 8: Run the Onboarding Wizard

This is where we configure OpenClaw with your AI provider. We use the CLI service for this:

```bash
docker compose run --rm openclaw-cli openclaw onboard
```

**Before you hit enter:** what do you think this does? `docker compose run --rm` means "spin up the CLI service, run a command, and remove the container when done." The `openclaw-cli` is the service name from our compose file. `openclaw onboard` is the command to run inside it.

This starts an interactive setup wizard. It'll ask you questions -- here's what to expect:

1. **AI Provider:** Choose Claude (Anthropic)
2. **API Key:** Paste the key you got in Step 6
3. **Model:** Choose Claude Sonnet (fast, smart, affordable)
4. Follow any additional prompts (name, personality, etc.)

> **Pro tip:** When pasting into a terminal, use `Ctrl+Shift+V` (Linux/Windows) or `Cmd+V` (Mac). Right-click also works in many terminals.

The onboarding wizard writes its config to `/home/node/.openclaw/openclaw.json` (JSON5 format). Because both the CLI and gateway share the same data volume, the gateway can read this config immediately.

### Step 9: Restart the Gateway

After onboarding, restart the gateway so it picks up the new config:

```bash
docker compose restart openclaw-gateway
```

### Step 10: Verify It Works

Check the gateway status:

```bash
docker compose run --rm openclaw-cli openclaw gateway status
```

You should see that the gateway is running and connected to your AI provider.

---

## Part 6: Create Your Telegram Bot (~5 minutes)

### Step 11: Talk to the BotFather

1. Open Telegram on your phone (or desktop app)
2. Search for **@BotFather** (it has a blue checkmark -- make sure it's the real one)
3. Tap **Start** or send `/start`
4. Send `/newbot`

### Step 12: Name Your Bot

BotFather will ask you two questions:

1. **"What name do you want for your bot?"** -- This is the display name. Pick anything fun:
   - `My OpenClaw`
   - `Jarvis`
   - `That AI Thing I Built`
   - Whatever makes you smile

2. **"Choose a username for your bot"** -- This must end in `bot`. For example:
   - `my_openclaw_bot`
   - `jarvis_personal_bot`
   - `cemergin_ai_bot`

### Step 13: Copy Your Bot Token

BotFather will respond with something like:

```
Done! Congratulations on your new bot. You will find it at t.me/my_openclaw_bot.

Use this token to access the HTTP API:
123456789:ABCdefGHIjklMNOpqrsTUVwxyz

Keep your token secure and store it safely.
```

Copy that token (the long string with the colon in the middle). You'll need it in the next step.

> **What just happened?** You created a Telegram bot. It exists now -- you can search for it in Telegram. It just doesn't do anything yet because there's nothing behind it. That's about to change.

---

## Part 7: Connect Telegram to OpenClaw (~5 minutes)

### Step 14: Add the Telegram Channel

Use the CLI service to add the Telegram channel:

```bash
docker compose run --rm openclaw-cli openclaw channels add telegram
```

It will ask for your Telegram Bot Token. Paste the token from Step 13.

OpenClaw will configure Telegram with **long polling** -- it reaches out to Telegram's servers to check for messages. No tunnel, no webhooks, no open ports. It just works.

> **Why long polling?** Because we're running locally. Your laptop doesn't have a public URL that Telegram can call back to. Long polling flips the direction -- OpenClaw asks Telegram "got anything for me?" every few seconds. It's all outbound traffic, which means it works from behind any firewall, any NAT, any coffee shop WiFi.

### Step 15: Restart the Gateway

After adding the channel, restart the gateway so it picks up the new channel config:

```bash
docker compose restart openclaw-gateway
```

Check the logs to confirm Telegram connected:

```bash
docker compose logs --tail 20 openclaw-gateway
```

Look for something like "Telegram bot connected" or "Listening for messages." If you see it, you're in business.

---

## Part 8: The Moment of Truth (~1 minute)

### Step 16: Send Your First Message

1. Open Telegram on your phone
2. Search for your bot's username (the one ending in `_bot`)
3. Tap **Start**
4. Type a message. Anything. Here are some ideas:
   - "Hello! Are you alive?"
   - "What's the meaning of life?"
   - "Explain quantum computing like I'm five"
   - "Write me a haiku about Docker containers"

**Before you send it:** take a breath. You installed Docker, started an AI agent in a container, created a Telegram bot, and wired them together. That message is about to travel from your phone, through Telegram's servers, to a Docker container on your laptop, through Claude's API, and back. All in a few seconds.

Now send it.

### Step 17: Wait for the Response

Watch your Telegram chat. Within a few seconds, you should see your bot typing... and then a response appears.

If you check the logs at the same time, you'll see the message being received and processed:

```bash
docker compose logs --tail 10 -f openclaw-gateway
```

(The `-f` flag means "follow" -- it streams new log entries in real time. Press `Ctrl+C` to stop watching.)

**It works.**

You just built a personal AI agent running in Docker on your laptop. You can message it from your phone as long as your laptop is on and Docker is running. It's yours.

---

## What Just Happened?

Let's recap what you built:

```
Your phone (Telegram)
  --> Telegram servers (relay)
    --> Docker on your laptop
      --> OpenClaw gateway (port 18789)
        --> Claude API (the brain)
          --> Response flows back to your phone
```

You now have:
- Docker Desktop running on your machine
- OpenClaw gateway running in a container with persistent data at `/home/node/.openclaw`
- A CLI service for on-demand admin commands
- A Telegram bot connected via long polling
- An AI agent you can message from your phone

**What you don't have (yet):**
- A server that runs 24/7 (close your laptop and the bot stops)
- Proper security (encrypted secrets, firewall)
- Monitoring (know when things break)
- A kill switch (emergency stop from your phone)
- Auto-deployment (git push to update)

That's what the full course (Modules 1-10) is for. But tonight? Tonight you have a working bot. Enjoy it.

---

## Troubleshooting

**Docker Desktop won't start:**
- **Mac:** Make sure you have enough disk space and RAM. Docker Desktop needs at least 2GB.
- **Windows:** Make sure WSL2 is enabled. Open PowerShell as admin and run `wsl --install`.
- Restart your machine and try again (seriously, this fixes most Docker startup issues).

**`docker compose up` fails:**
- Make sure Docker Desktop is running (check the whale icon in your system tray)
- Make sure you're in the right directory (where your `docker-compose.yml` file is)
- Check the error message -- it usually tells you what's wrong

**OpenClaw onboarding fails:**
- Make sure the gateway is running: `docker compose ps`
- Check the logs: `docker compose logs openclaw-gateway`
- Try stopping and restarting: `docker compose down && docker compose up -d`

**Bot doesn't respond to messages:**
- Check the logs: `docker compose logs --tail 50 openclaw-gateway`
- Verify your Telegram token is correct: try the channel add step again
- Make sure the gateway is running: `docker compose ps`
- Check your API key has billing enabled (Claude requires a payment method)
- Run diagnostics: `docker compose run --rm openclaw-cli openclaw doctor`

**"Insufficient funds" or API errors:**
- Make sure you've added billing info to your Anthropic account
- Check your API dashboard for any error messages
- Make sure your spending limit hasn't been reached

**Container keeps restarting:**
- Check the logs immediately after it starts: `docker compose logs -f openclaw-gateway`
- The most common cause is a bad API key or missing onboarding

**Everything else:**
- Run diagnostics: `docker compose run --rm openclaw-cli openclaw doctor`
- Check the [OpenClaw docs](https://openclaw.ai)
- The full course (starting with Module 1) covers everything in much more detail

---

## Quick Reference

Here are the commands you'll use most:

```bash
# Start the gateway
docker compose up -d

# Stop everything
docker compose down

# Check what's running
docker compose ps

# View gateway logs
docker compose logs openclaw-gateway
docker compose logs --tail 20 -f openclaw-gateway

# Restart the gateway
docker compose restart openclaw-gateway

# Run CLI commands (onboarding, config, channels)
docker compose run --rm openclaw-cli openclaw onboard
docker compose run --rm openclaw-cli openclaw channels add telegram
docker compose run --rm openclaw-cli openclaw gateway status
docker compose run --rm openclaw-cli openclaw doctor

# Open a shell inside the CLI container
docker compose run --rm openclaw-cli bash
```

When you're done playing, head to the [challenge](challenge.md) for some fun customization ideas.

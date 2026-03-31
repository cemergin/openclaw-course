# Speed Run -- Your Bot Tonight

## What if your phone had a genius on call?

Imagine this: you're on the subway, spotty connection, and you need to draft a tricky email to your manager. Or you're lying in bed and want to brainstorm product ideas. Or you just want to ask "what's the capital of Burkina Faso" without opening a browser.

What if you could just... text someone who always has the answer?

That's what we're building tonight. An AI agent running in Docker on your laptop, connected to Telegram, powered by Claude (or GPT -- your choice). You message it from your phone like a normal conversation. It responds as long as your laptop is on and Docker is running.

The best part? It runs on *your* hardware, with *your* API key. No middleman. No subscription. No "we've updated our privacy policy" emails.

Let's do this.

## The 30-Second Version: What Is OpenClaw?

[OpenClaw](https://openclaw.ai) is an open-source personal AI agent. Here's what that means in plain English:

- **Open-source** -- the code is public, free, and you can see exactly what it does
- **Personal** -- it's yours, running on your machine, with your data
- **AI agent** -- it doesn't just answer questions; it has persistent memory, connects to 50+ services, and can take actions on your behalf

Think of it as your own private ChatGPT that remembers everything you've told it and can eventually connect to your GitHub, Gmail, Notion, calendar... everything.

## How the Pieces Fit Together

Here's the architecture in one picture:

```
You (phone)
  --> Telegram app
    --> Telegram's servers
      --> OpenClaw gateway in Docker on your laptop (port 18789)
        --> Claude API (the AI brain)
          --> Response flows back the same path
```

Four moving parts. That's it:

1. **Your phone** -- where you type messages in Telegram
2. **Telegram's servers** -- they relay messages to your bot
3. **Docker on your laptop** -- running the OpenClaw gateway in a container
4. **Claude/GPT API** -- the AI model that generates responses

Tonight we're going to set up parts 2, 3, and 4. Part 1 you already have (it's your phone).

## Concepts You Need (Just Enough to Be Dangerous)

### Docker = Software in a Box

Instead of installing OpenClaw directly on your system (messy, version conflicts, "works on my machine" headaches), we run it inside a **container**. Think of Docker as a shipping container for software -- a standardized box that works the same on every machine.

You don't need to understand Docker deeply tonight. Here's all you need to know:

- **Docker Desktop** is the app you install on your Mac/Windows/Linux machine
- A **container** is a running box of software (OpenClaw lives in one)
- **docker-compose** is a file that says "run these containers with these settings"
- You start everything with `docker compose up` and stop it with `docker compose down`

That's it. The full course (Module 2) goes deep on Docker. Tonight we just use it.

> **Pro tip:** Docker Desktop is free for personal use and small businesses. It runs on Mac, Windows, and Linux.

### The Two-Service Pattern

OpenClaw's Docker setup uses two services that share the same data volume:

- **openclaw-gateway** -- the always-running service. This is your agent: it listens for Telegram messages, talks to Claude, manages memory, runs tools. It exposes port 18789 for its web interface and API.
- **openclaw-cli** -- the on-demand service. You use this for setup commands like onboarding, adding channels, checking status. It only runs when you explicitly call it (via `docker compose run --rm openclaw-cli ...`).

Both use the same Docker image (`ghcr.io/openclaw/openclaw:latest`) and share the same data volume at `/home/node/.openclaw`. The CLI writes config, the gateway reads it. Simple.

### API Keys = Passwords for AI Services

Claude and GPT aren't free -- they charge per use (usually fractions of a cent per message). An API key is like a password that identifies you to their billing system. You create one, paste it into OpenClaw's config, and it uses your key to call Claude whenever you send a message.

Typical cost for personal use: **$1-5 per month**. Seriously. AI is cheap when you're not paying for a fancy UI.

### Telegram Bots = The Easiest Chat Interface

Telegram lets anyone create a bot in about 30 seconds through their @BotFather bot (yes, a bot that makes bots -- we live in the future). You get a token, plug it into OpenClaw, and your bot is live.

We're using Telegram because it supports **long polling** -- that means OpenClaw reaches *out* to Telegram's servers to check for new messages. It's all outbound traffic. No need to open ports, set up tunnels, or configure your router. It just works from your laptop.

### Long Polling: Why This Works Locally

Here's the magic trick that makes tonight possible. With long polling, OpenClaw says to Telegram: "Hey, got any new messages for me?" every few seconds. Telegram answers "nope" or "yes, here's one." It's like refreshing your email.

Because OpenClaw is the one making the request (outbound), it works from behind your home WiFi, your office firewall, a coffee shop -- anywhere. No tunnel, no domain name, no port forwarding. Just an internet connection.

This is different from **webhooks**, where Telegram would try to *call* your server (which requires a public URL). We'll use webhooks when we move to a VPS in the full course. Tonight, long polling is our friend.

## What We're NOT Doing Tonight

Let's be honest about the corners we're cutting:

- **No cloud server** -- everything runs on your laptop (close the lid and the bot stops)
- **No firewall configuration** -- we're running locally, so it's not exposed to the internet
- **No encrypted secrets** -- API keys go in a compose file on your machine
- **No monitoring** -- if it crashes, you'll see it in the terminal
- **No auto-restart** -- if Docker restarts, you re-run the command

Is this okay for daily use? Not really. Is it okay for tonight? Absolutely yes.

The full course (Modules 1-10) rebuilds everything properly -- a server that runs 24/7, Docker with proper secrets management, Cloudflare Tunnel for zero open ports, monitoring, and a kill switch you can trigger from your phone. But none of that matters if you never get the dopamine hit of seeing it work.

So let's get that dopamine hit first. Production readiness can wait until tomorrow.

## The Game Plan

Here's what we're doing in the next couple of hours:

1. **Install Docker Desktop** (~10 min, or skip if you already have it)
2. **Create a docker-compose.yml** (~5 min)
3. **Start OpenClaw in Docker** (~5 min)
4. **Run onboarding via the CLI service** (~10 min)
5. **Get a Claude API key** (~5 min)
6. **Create a Telegram bot** (~5 min)
7. **Connect Telegram to OpenClaw** (~5 min)
8. **Send your first message** (~1 min, but you'll spend 30 min playing with it)

Total: about an hour of actual work, plus whatever time you spend gleefully messaging your new AI agent at midnight.

Ready? Head to the [exercise](exercise.md) and let's build this thing.

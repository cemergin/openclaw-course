# Speed Run -- Your Bot Tonight

## What if your phone had a genius on call?

Imagine this: you're on the subway, spotty connection, and you need to draft a tricky email to your manager. Or you're lying in bed and want to brainstorm product ideas. Or you just want to ask "what's the capital of Burkina Faso" without opening a browser.

What if you could just... text someone who always has the answer?

That's what we're building tonight. An AI agent that lives on a server you control, connected to Telegram, powered by Claude (or GPT -- your choice). You message it from your phone like a normal conversation. It responds 24/7, even when your laptop is off, even when you're on airplane mode with just enough signal for a text.

The best part? It runs on *your* hardware, with *your* API key. No middleman. No subscription. No "we've updated our privacy policy" emails.

Let's do this.

## The 30-Second Version: What Is OpenClaw?

[OpenClaw](https://openclaw.ai) is an open-source personal AI agent. Here's what that means in plain English:

- **Open-source** -- the code is public, free, and you can see exactly what it does
- **Personal** -- it's yours, running on your server, with your data
- **AI agent** -- it doesn't just answer questions; it has persistent memory, connects to 50+ services, and can take actions on your behalf

Think of it as your own private ChatGPT that never sleeps, remembers everything you've told it, and can eventually connect to your GitHub, Gmail, Notion, calendar... everything.

## How the Pieces Fit Together

Here's the architecture in one picture:

```
You (phone)
  --> Telegram app
    --> Telegram's servers
      --> OpenClaw on your VPS (a cheap cloud server)
        --> Claude API (the AI brain)
          --> Response flows back the same path
```

Four moving parts. That's it:

1. **Your phone** -- where you type messages in Telegram
2. **Telegram's servers** -- they relay messages to your bot
3. **Your VPS** -- a little computer in the cloud running OpenClaw 24/7
4. **Claude/GPT API** -- the AI model that generates responses

Tonight we're going to set up parts 2, 3, and 4. Part 1 you already have (it's your phone).

## Concepts You Need (Just Enough to Be Dangerous)

### VPS = A Computer in the Cloud

A VPS (Virtual Private Server) is literally just a computer sitting in a data center somewhere. You rent it by the month. It stays on 24/7. It has an internet connection way faster than yours.

We're using **AWS Lightsail** because it's the simplest way to get a server on AWS. The $5/month plan gives us 1 CPU, 1 GB of RAM, and 40 GB of storage. That's more than enough for OpenClaw.

> **Pro tip:** AWS gives you 3 months free on the $5 plan. So tonight costs you literally nothing.

### SSH = Remote Control

Your VPS doesn't have a screen or keyboard. SSH (Secure Shell) is how you control it -- you type commands on your laptop, and they run on the server. Think of it as a really secure remote desktop, but text-only.

```
Your laptop terminal  ---SSH connection--->  Your VPS
    (you type here)                          (commands run here)
```

### API Keys = Passwords for AI Services

Claude and GPT aren't free -- they charge per use (usually fractions of a cent per message). An API key is like a password that identifies you to their billing system. You create one, paste it into OpenClaw, and it uses your key to call Claude whenever you send a message.

Typical cost for personal use: **$1-5 per month**. Seriously. AI is cheap when you're not paying for a fancy UI.

### Telegram Bots = The Easiest Chat Interface

Telegram lets anyone create a bot in about 30 seconds through their @BotFather bot (yes, a bot that makes bots -- we live in the future). You get a token, plug it into OpenClaw, and your bot is live.

We're using Telegram for the speed run because it requires zero infrastructure on your end -- no webhooks, no domains, no certificates. The full course switches to WhatsApp with proper security, but tonight is about speed.

## What We're NOT Doing Tonight

Let's be honest about the corners we're cutting:

- **No firewall configuration** -- your server will have default security
- **No dedicated user** -- we're running as root (gasp!)
- **No Docker** -- we're installing directly on the server
- **No encrypted secrets** -- API keys go in plain config files
- **No monitoring** -- if it crashes at 3am, you won't know until morning

Is this okay for production? Absolutely not. Is it okay for tonight? Absolutely yes.

The full course (Modules 1-12) rebuilds everything properly -- Docker containers, Cloudflare Tunnel for zero open ports, encrypted secrets, monitoring, a kill switch you can trigger from your phone. But none of that matters if you never get the dopamine hit of seeing it work.

So let's get that dopamine hit first. Security can wait until tomorrow.

## The Game Plan

Here's what we're doing in the next couple of hours:

1. **Create an AWS Lightsail instance** (~15 min)
2. **SSH into it** (~5 min)
3. **Install OpenClaw** (~10 min)
4. **Get a Claude API key** (~5 min)
5. **Create a Telegram bot** (~5 min)
6. **Run OpenClaw onboarding** (~10 min)
7. **Send your first message** (~1 min, but you'll spend 30 min playing with it)

Total: about an hour of actual work, plus whatever time you spend gleefully messaging your new AI agent at midnight.

Ready? Head to the [exercise](exercise.md) and let's build this thing.

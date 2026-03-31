# Episode 3: OpenClaw Deep Dive + Config-as-Code

## In This Episode

This is the meatiest module in Loop 1. You already got OpenClaw running in the Speed Run or in Module 2. Now we go deep. You'll understand how OpenClaw actually works under the hood -- the gateway architecture, the config system, skills, memory, tools, and channels. Then you'll build the config-as-code repository that carries through the entire rest of this course. Every module from here forward builds on this repo.

### Key Concepts

- **OpenClaw architecture** -- gateway, agent loop, tools, channels, and how they connect
- **Config-as-Code** -- your bot's personality, skills, and settings live in a Git repo
- **JSON5 config** -- OpenClaw's config format with $include support and SecretRef pattern
- **Skills system** -- reusable capabilities from ClawHub or custom-built
- **Memory system** -- MEMORY.md for long-term, daily notes, and SQLite search
- **35+ built-in tools** -- shell, browser, web search, code execution, file I/O, and more
- **23+ chat channels** -- Telegram, Discord, Slack, Signal, iMessage, IRC, and more
- **Multi-model support** -- Anthropic, OpenAI, Google, Ollama, OpenRouter, and 20+ providers

### Prerequisites

You should have completed Module 2 (Docker on Your Machine). You need Docker running on your laptop.

You'll also need:
- An **Anthropic API key** (for Claude) -- or an OpenAI key if you prefer GPT
- A **Telegram account** on your phone

**Self-check:** Run `docker compose version`. See a version number? You're ready.

### Builds On

- **Module 2: Docker on Your Machine** -- you know Docker Compose, volumes, networks, and port mapping

### What's Next

Here's the thing: when you close your laptop, the bot stops. That's the limitation of running locally. In **Module 4**, we'll set up a VPS -- a server in the cloud that runs 24/7 -- and move OpenClaw there so your bot never sleeps. The config-as-code repo you build here? It deploys to that server with a simple `git push`.

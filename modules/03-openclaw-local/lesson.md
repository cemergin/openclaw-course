# Lesson 3: OpenClaw Deep Dive + Config-as-Code

## The Payoff Moment

We've been building up to this. Module 2 taught you Docker. Now we use it for real. By the end of this lesson, you'll understand how OpenClaw works under the hood and have a config-as-code repo that defines your entire bot. This repo carries through the rest of the course -- it's what you'll deploy to a server, version in Git, and iterate on for months.

Let's start with how the pieces fit together.

## OpenClaw Architecture

OpenClaw isn't just "a chatbot." It's a full agent platform with several layers. Here's the mental model:

```
                    +---------------------------+
                    |       Chat Channels        |
                    | Telegram, Discord, Slack,  |
                    | Signal, iMessage, IRC...   |
                    +-------------+-------------+
                                  |
                    +-------------v-------------+
                    |        Gateway             |
                    |    (port 18789)            |
                    |  Routes messages to agents |
                    +-------------+-------------+
                                  |
                    +-------------v-------------+
                    |      Agent Loop            |
                    |  Model + SOUL.md + Memory  |
                    |  + Skills + Tools          |
                    +----+--------+--------+----+
                         |        |        |
                    +----v--+ +---v---+ +--v----+
                    | Tools | | Skills| |Memory |
                    | 35+   | | SKILL | |MEMORY |
                    |built-in| | .md   | |.md    |
                    +-------+ +-------+ +-------+
```

### The Gateway

The gateway is the core process. When you start OpenClaw, you're starting the gateway. It:

- Listens on **port 18789** for its web interface and API
- Connects to chat channels (Telegram, Discord, etc.) via long polling or webhooks
- Routes incoming messages to the right agent
- Manages the agent loop (model calls, tool execution, memory updates)
- Runs as the `node` user (uid 1000) inside the Docker container

All its data lives at `/home/node/.openclaw/` -- config, workspace, memory, database.

### The Agent Loop

When a message comes in, here's what happens:

1. The channel (e.g., Telegram) receives the message and passes it to the gateway
2. The gateway figures out which agent should handle it (via bindings)
3. The agent loads its context: SOUL.md (personality), IDENTITY.md (name/role), MEMORY.md (long-term memory), and the current conversation
4. It calls the AI model (Claude, GPT, etc.) with all that context
5. The model may request tool use (browse a website, run code, search the web)
6. If tools are called, the results go back to the model for another pass
7. The final response goes back through the channel to the user
8. Memory is updated (conversation history + any notable facts to MEMORY.md)

This loop can run multiple times per message if the model uses tools. That's what makes it an *agent* and not just a chatbot -- it can take actions, observe results, and reason about next steps.

## Config Format: JSON5

OpenClaw's main config file is `openclaw.json` (technically JSON5 -- like JSON but with comments and trailing commas). It lives at `~/.openclaw/openclaw.json`.

Here's a simplified example:

```json5
{
  // AI model configuration
  model: {
    provider: "anthropic",
    model: "claude-sonnet-4-20250514",
    apiKey: { source: "env", id: "ANTHROPIC_API_KEY" },
  },

  // Chat channels
  channels: {
    telegram: {
      enabled: true,
      token: { source: "env", id: "TELEGRAM_BOT_TOKEN" },
      polling: true,
    },
  },

  // Agent configuration
  agents: {
    default: {
      soul: "$include:workspace/SOUL.md",
      identity: "$include:workspace/IDENTITY.md",
      skills: ["workspace/skills/*"],
    },
  },
}
```

A few things to notice:

### The SecretRef Pattern

See those `{ source: "env", id: "..." }` objects? That's the **SecretRef** pattern. Instead of putting secrets directly in your config, you tell OpenClaw *where* to find them. Three sources:

- **`env`** -- read from an environment variable: `{ source: "env", id: "ANTHROPIC_API_KEY" }`
- **`file`** -- read from a file on disk: `{ source: "file", id: "/path/to/secret.txt" }`
- **`exec`** -- run a command and use its output: `{ source: "exec", id: "vault kv get -field=key secret/openclaw" }`

This is how you keep secrets out of your config files. The config says "look in the environment for ANTHROPIC_API_KEY" -- the actual key is never in the file. In Module 7 (Security), we'll switch from `env` to `file` for proper secret management on the server.

### The $include Directive

`"$include:workspace/SOUL.md"` means "read the contents of that file and insert them here." This lets you keep long text (like personality descriptions) in separate files instead of cramming them into JSON. Clean.

## The Personality Layer: SOUL.md and IDENTITY.md

These two files define *who* your agent is.

**IDENTITY.md** is short and factual:

```markdown
Name: Atlas
Role: Personal AI assistant
Creator: Your Name
```

**SOUL.md** is where the magic happens. This is the system prompt -- the personality instructions that shape every response:

```markdown
You are Atlas, a thoughtful and slightly witty personal AI assistant.

You speak clearly and concisely. You prefer to give direct answers first,
then offer to elaborate. You have a dry sense of humor that surfaces
occasionally but never at the expense of being helpful.

When you don't know something, you say so honestly. You never make up facts.

You're comfortable with technical topics but explain things in plain language
unless the user signals they want technical depth.
```

Change SOUL.md, restart the gateway, and your bot has a completely different personality. We'll do exactly this in the exercise.

## The Skills System

Skills are reusable capabilities that extend your agent. A skill is just a directory with a `SKILL.md` file that describes what the skill does and how to use it.

```
workspace/skills/
  summarizer/
    SKILL.md        # Describes the skill
    templates/      # Optional: prompt templates
    config.json     # Optional: skill-specific config
  code-reviewer/
    SKILL.md
```

The `SKILL.md` file is written in natural language -- it's instructions for the AI model about when and how to use the skill. Think of it as a mini system prompt that gets loaded when the skill is relevant.

### ClawHub: The Skills Marketplace

OpenClaw has a marketplace called **ClawHub** where you can discover and install community-created skills. Install a skill with one command:

```bash
openclaw skills install clawhub/summarizer
```

This downloads the skill into your `workspace/skills/` directory. You can inspect it, modify it, or remove it. Skills are just files -- no magic, no compiled code.

## The Memory System

OpenClaw has a three-tier memory system:

### 1. Conversation History (Short-Term)

Every conversation is stored in a SQLite database. The agent loads recent messages as context for each response. This is how it knows what you've been talking about.

### 2. MEMORY.md (Long-Term)

This is a Markdown file where the agent stores important facts it learns about you across conversations. Things like:

```markdown
## User Preferences
- Prefers concise answers
- Works in Python and TypeScript
- Lives in San Francisco
- Vegetarian

## Projects
- Working on a side project called "RecipeBot"
- Uses AWS for infrastructure
```

The agent reads this file at the start of every conversation and updates it when it learns something new. It's like the agent's long-term memory -- persistent across restarts and conversations.

### 3. Daily Notes (Session Memory)

Each day gets a file at `memory/YYYY-MM-DD.md`. These capture session-specific context -- what was discussed, what was decided, what to follow up on. It's like a daily journal for the agent.

## 35+ Built-In Tools

This is where OpenClaw gets powerful. Out of the box, it can:

**Shell and Code:**
- Run shell commands on the host system
- Execute Python, JavaScript, and other code
- Read and write files on disk

**Web and Browser:**
- Browse websites with a built-in Chromium instance (headless)
- Search the web
- Fetch and parse web pages

**Communication:**
- Send messages across channels
- Schedule messages and reminders (cron-based)

**Media:**
- Generate and process images
- Handle file attachments

**System:**
- Manage its own config
- Install and configure skills
- Query its memory and conversation history

The tools are controlled by permissions in the config. You can enable/disable individual tools or restrict what they can access. In Module 7 (Security), we'll lock down the dangerous ones.

> **A note on trust:** Some of these tools are powerful. Shell access means the agent can run commands on your machine. Browser access means it can visit websites. For now, this is running on your laptop in a Docker container, so the blast radius is limited. When we move to a server, we'll tighten permissions.

## 23+ Chat Channels

You've been using Telegram. But OpenClaw supports a lot more:

- **Telegram** -- what we're using (long polling, easy setup)
- **Discord** -- great for server/community bots
- **Slack** -- workplace integration
- **Signal** -- privacy-focused messaging
- **iMessage** -- Apple ecosystem (requires macOS host)
- **IRC** -- old school, still works
- **Matrix** -- decentralized messaging
- **WhatsApp** -- via bridges
- And 15+ more, including email and SMS

Each channel is configured in `openclaw.json` with its own credentials and settings. One gateway can connect to multiple channels simultaneously -- you could message the same bot on Telegram and Discord and it maintains context across both.

## Multi-Model Support

OpenClaw isn't locked to one AI provider. It supports 20+ model providers:

- **Anthropic** -- Claude Sonnet, Opus, Haiku
- **OpenAI** -- GPT-4o, GPT-4o-mini, o1
- **Google** -- Gemini Pro, Gemini Flash
- **Ollama** -- run open-source models locally (Llama, Mistral, etc.)
- **OpenRouter** -- access 100+ models through one API
- And many more (Groq, Together, Replicate, AWS Bedrock, Azure OpenAI...)

You can switch models by changing one line in `openclaw.json`. You can even run multiple agents on the same gateway with different models -- one using Claude for complex tasks, another using a cheap local model via Ollama for quick answers.

## Agent Routing: Multiple Agents Per Gateway

A single OpenClaw gateway can run multiple agents. Each agent has its own:

- Personality (SOUL.md)
- Model provider and model
- Skills
- Channel bindings (which channels it responds on)

The `bindings` config maps channels to agents. You might have:

- A "work" agent on Slack using GPT-4o
- A "personal" agent on Telegram using Claude Sonnet
- A "research" agent on Discord using Claude Opus

All running on the same gateway, sharing the same infrastructure. We won't set this up today (one agent is plenty to start), but it's good to know it's there.

## OpenClaw's Docker Image

The official image is `ghcr.io/openclaw/openclaw:latest`, hosted on GitHub Container Registry.

Inside the container:
- The process runs as the `node` user (uid 1000)
- All data lives at `/home/node/.openclaw/`
- Config: `/home/node/.openclaw/openclaw.json`
- Workspace: `/home/node/.openclaw/workspace/` (SOUL.md, IDENTITY.md, skills/)
- Memory: `/home/node/.openclaw/workspace/memory/`
- The gateway listens on port 18789

We use the **two-service pattern** in our Docker Compose:

- **openclaw-gateway** -- the always-running service
- **openclaw-cli** -- on-demand for setup commands (uses `profiles: ["cli"]`)

Both share the same data volume. The CLI writes config, the gateway reads it.

## The Docker Compose File

Here's what the compose file looks like:

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

Let's break it down:

- **`image: ghcr.io/openclaw/openclaw:latest`** -- the official image from GitHub Container Registry
- **`container_name: openclaw-gateway`** -- so we can identify it in logs and commands
- **`restart: unless-stopped`** -- auto-restart on crash (but not if you explicitly stop it)
- **`ports: "18789:18789"`** -- expose the gateway's web UI and API
- **`volumes: openclaw-data:/home/node/.openclaw`** -- persistent data survives container recreation
- **`profiles: ["cli"]`** -- the CLI service only starts when explicitly invoked

Notice the `ports:` section. Unlike Module 0 where we said "no ports needed," here we expose 18789 so you can access the web interface locally. The gateway also connects outward to Telegram (long polling), so no inbound ports are needed for chat to work.

## Long Polling vs Webhooks (Quick Recap)

**Long polling** -- OpenClaw asks Telegram "got messages?" every few seconds. All outbound traffic. Works from behind any firewall. This is what we use locally.

**Webhooks** -- Telegram pushes messages to a URL you provide. More efficient, but requires a public HTTPS endpoint. That's Module 8 (Cloudflare Tunnel) territory.

For local development, long polling is perfect. When we move to a server, we can optionally switch to webhooks for lower latency.

## What Happens When You Close Your Laptop

The cliffhanger from Module 0 is still real:

1. The Docker container suspends
2. The long polling connection to Telegram drops
3. Your bot stops responding

Messages sent while offline? Telegram queues them. When you open your laptop and the container resumes, OpenClaw processes the backlog. Nothing is lost -- but there's a delay.

Want 24/7 availability? That's Module 4 (VPS) and Module 5 (git push deploy).

## Config-as-Code: The Key Idea

Here's the big idea that makes this module special: **your entire bot is defined by files in a Git repository.** Not by clicking through a UI. Not by SSH-ing into a server and hand-editing. Files in a repo.

This means:

- **Version control** -- every change is tracked, diffable, revertable
- **Reproducibility** -- clone the repo, provide secrets, and you have an identical bot
- **Deployment** -- `git push` triggers deployment (Module 5)
- **Collaboration** -- share your config (sans secrets) with others
- **Disaster recovery** -- lost your server? Clone the repo, spin up a new one, done

In the exercise, you'll create this repo. It starts simple and grows with every module. By the end of the course, it contains everything needed to deploy and run your bot.

The repo structure:

```
my-openclaw/
  config/
    openclaw.json       # Main config (model, channels, agents)
  workspace/
    SOUL.md             # Bot personality
    IDENTITY.md         # Bot name and role
    skills/             # Custom and installed skills
  docker-compose.yml    # Support services (filled in later modules)
  secrets/              # .gitignored -- never committed
    .gitkeep
  .gitignore
```

The critical insight: **secrets stay out of Git.** The config *references* secrets via SecretRef (`{ source: "env", id: "..." }` or `{ source: "file", id: "..." }`), but the actual keys live in the `secrets/` directory (gitignored) or in environment variables. Your repo is safe to push to GitHub, even to a public repo.

Ready to build this? Head to the [exercise](exercise.md).

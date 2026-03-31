# Speed Run Cheatsheet

Quick reference for all commands used in Module 0.

## Docker Basics

```bash
# Check Docker is installed
docker --version
docker compose version

# Start OpenClaw (from your project folder)
docker compose up -d

# Stop OpenClaw
docker compose down

# Restart the gateway
docker compose restart openclaw-gateway

# Check what's running
docker compose ps

# View logs (last 20 lines, follow new output)
docker compose logs --tail 20 -f openclaw-gateway

# View all logs
docker compose logs openclaw-gateway
```

## OpenClaw Commands (via the CLI service)

```bash
# Run onboarding (set up AI provider, API key, etc.)
docker compose run --rm openclaw-cli openclaw onboard

# Add a Telegram channel
docker compose run --rm openclaw-cli openclaw channels add telegram

# Check gateway status
docker compose run --rm openclaw-cli openclaw gateway status

# Run diagnostics
docker compose run --rm openclaw-cli openclaw doctor

# Open a shell inside the CLI container
docker compose run --rm openclaw-cli bash
```

## Telegram Bot Setup

1. Open Telegram, search for **@BotFather**
2. Send `/newbot`
3. Choose a display name (anything you want)
4. Choose a username (must end in `bot`)
5. Copy the token BotFather gives you

## API Key Sources

| Provider | Console URL | Key prefix |
|----------|------------|------------|
| Anthropic (Claude) | console.anthropic.com | `sk-ant-...` |
| OpenAI (GPT) | platform.openai.com | `sk-...` |

## Troubleshooting

```bash
# Gateway won't start? Check logs:
docker compose logs openclaw-gateway

# Need to start fresh?
docker compose down -v
docker compose up -d

# Is Docker even running?
docker info

# Run OpenClaw diagnostics
docker compose run --rm openclaw-cli openclaw doctor
```

## File Locations

- **Project folder:** `~/openclaw-local/`
- **Compose file:** `~/openclaw-local/docker-compose.yml`
- **Config inside container:** `/home/node/.openclaw/openclaw.json`
- **Data volume:** Managed by Docker (persistent across restarts)

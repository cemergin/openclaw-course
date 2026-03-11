# Speed Run Cheat Sheet

Keep this open in a separate tab while following the exercise.

## Accounts You Need

| Service | URL | What You Get |
|---------|-----|-------------|
| AWS | [aws.amazon.com](https://aws.amazon.com/) | Cloud server (Lightsail) |
| Anthropic | [console.anthropic.com](https://console.anthropic.com/) | Claude API key (`sk-ant-...`) |
| OpenAI (alt) | [platform.openai.com](https://platform.openai.com/) | GPT API key (`sk-...`) |
| Telegram | @BotFather in Telegram app | Bot token (`123456:ABC...`) |

## SSH Connection

```bash
# Set key permissions (once)
chmod 400 ~/Downloads/LightsailDefaultKey-*.pem

# Connect
ssh -i ~/Downloads/LightsailDefaultKey-*.pem ubuntu@YOUR_IP
```

## Server Setup Commands

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Install OpenClaw
curl -fsSL https://openclaw.ai/install.sh | bash

# Configure
openclaw onboard

# Start
openclaw start

# Start in background (persists after disconnect)
nohup openclaw start > ~/openclaw.log 2>&1 &
```

## Daily Operations

```bash
# Check if running
ps aux | grep openclaw

# View logs
tail -50 ~/openclaw.log

# Stop
openclaw stop

# Restart
openclaw stop && nohup openclaw start > ~/openclaw.log 2>&1 &
```

## Your Info (Fill In)

- Server IP: ____________________
- Claude API key: sk-ant-_______________  (keep secret!)
- Telegram bot username: @_______________
- Telegram bot token: ___________________  (keep secret!)

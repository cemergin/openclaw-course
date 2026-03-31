# Episode 6: It's Alive -- Verifying on the Instance

## Bringing OpenClaw to Life on Your VPS

### In This Episode

Your files are on the server. OpenClaw is installed. The deploy pipeline works. But the gateway isn't *running* yet -- it's like having a car in the garage with the engine off. In this module, you'll verify everything is in place, start the OpenClaw gateway, run the doctor check, peek at the dashboard through an SSH tunnel, and then experience the magic moment: you close your laptop, send a Telegram message from your phone, and your AI agent responds. From a server you built. That's running without you. That's the whole point.

### Key Concepts

- **OpenClaw gateway** -- the process that receives messages and routes them to Claude
- **openclaw doctor** -- the built-in diagnostic tool that validates your setup
- **SSH tunneling** -- securely viewing the dashboard without exposing ports
- **Daily operations** -- the handful of commands you'll use every day (no docker exec needed!)
- **The big payoff** -- closing your laptop and watching your agent keep working

### Prerequisites

You should have completed Module 5 (GitHub Actions deploying config to your VPS). Your `config/openclaw.json` and `workspace/SOUL.md` should be in `~/.openclaw/` on the server.

> **Self-check:** Can you `ssh openclaw`, run `ls ~/.openclaw/openclaw.json`, and see the config file? Run `cat ~/.openclaw/workspace/SOUL.md` and see your personality file? You're ready to bring it to life.

### Builds On

- **Module 3: OpenClaw Local** -- you know how OpenClaw works from running it locally
- **Module 4: Your Computer in the Sky** -- Node.js, OpenClaw, and Docker are installed
- **Module 5: Git Push to Deploy** -- your config files are deployed to the right places

### What's Next

- **Module 7** -- now that your agent is alive, we'll add more capabilities and harden the setup

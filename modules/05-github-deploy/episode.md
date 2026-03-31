# Episode 5: Git Push to Deploy

## Config-as-Code Deployment with GitHub Actions

### In This Episode

You built a config-as-code repo in Module 3 -- it has your OpenClaw configuration, your SOUL.md personality file, your workspace skills, and a docker-compose.yml for support services. Right now, that repo lives on your laptop. In this module, you'll connect it to your VPS so that a `git push` automatically deploys everything. Edit SOUL.md locally, push, and your agent's personality changes on the server. That's the magic of config-as-code deployment.

### Key Concepts

- **Config-as-code** -- your agent's entire personality and configuration lives in a git repo
- **GitHub Actions** -- automated workflows that run on every push
- **SSH deploy via appleboy/ssh-action** -- executing commands on your VPS from a GitHub Action
- **GitHub Secrets** -- encrypted variables for storing SSH keys and server details
- **The deploy flow** -- git pull, copy configs, update OpenClaw, restart gateway, start support services

### Prerequisites

You should have completed Module 4 (VPS with Node.js, OpenClaw, and Docker installed, deploy user created, SSH access working). You need a GitHub account and the config-as-code repo from Module 3.

> **Self-check:** Can you `ssh openclaw` and run `openclaw --version`? Do you have a GitHub account and a config-as-code repo with `config/openclaw.json` and `workspace/SOUL.md`? You're ready.

### Builds On

- **Module 3: OpenClaw Local** -- the config-as-code repo you built is what gets deployed
- **Module 4: Your Computer in the Sky** -- the server, deploy user, and installed software are where it all lands

### What's Next

- **Module 6: It's Alive -- Verifying on the Instance** -- files are deployed, but is OpenClaw actually running? Next up: bringing the gateway to life and verifying it works

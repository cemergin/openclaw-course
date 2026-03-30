# Episode 10: Git Push to Deploy

## No More Nano on the Server

### In This Episode

You've been SSH-ing into your server and hand-editing files with nano. That worked for learning -- you understood every line because you typed every line. But it's error-prone (YAML indentation, anyone?), not repeatable (if your server dies, can you rebuild from memory?), and not auditable (no history of what changed when). Time to fix that. You'll set up a private GitHub repo for your configuration files, create a simple deploy script, and never nano a compose file on the server again. Push to GitHub, pull on the server, done.

### Key Concepts

- **Infrastructure as Code** -- your server configuration lives in git, not in someone's memory
- **Private GitHub repos** -- your compose files and scripts, version-controlled but not public
- **Fine-grained GitHub tokens** -- scoped to one repo, read-only, least privilege
- **The deploy script** -- a simple shell script that pulls and restarts services
- **Secrets stay on the server** -- config in git, secrets in ~/openclaw/secrets/ (never committed)
- **`.gitignore` as a security boundary** -- making sure secrets can't accidentally end up in git

### Prerequisites

You should have completed Module 9 (full Docker Compose deployment). You need a working OpenClaw stack, a GitHub account, and SSH access to your VPS.

> **Self-check:** Is your full stack running with `docker compose up -d`? Can you message your bot on WhatsApp and get a response? You're ready to stop hand-editing and start deploying properly.

### Builds On

- **Module 4: Containers** -- Docker Compose files are the main thing you'll version-control
- **Module 6: Secrets Management** -- the secrets/ directory stays on the server, never in git
- **Module 9: Ship It** -- you have a working docker-compose.yml to put under version control

### What's Next

In **Module 11: Is It Still Alive? -- Monitoring and Alerts**, you'll set up the third leg of the lethal trifecta. With your config in git, you can now track what changed if something breaks -- "did a config change cause this, or is it something else?"

# Episode 6: Secrets Management -- Not Just a .env File

## Storing API Keys and Tokens Properly

### In This Episode

You've got API keys for Claude, WhatsApp, maybe GitHub and Notion -- and right now they're probably sitting in a `.env` file that anyone with shell access can read in under two seconds. That's the "exposed secrets" leg of the lethal trifecta from Module 5, and we're going to fix it. You'll learn why environment variables leak in ways that would make you queasy, implement Docker file-based secrets (the recommended approach), and understand two advanced alternatives for when you want to go further. By the end, your secrets will be invisible to `docker inspect`, absent from logs, and locked behind proper file permissions.

### Key Concepts

- **Why .env files leak** -- docker inspect, /proc filesystem, child processes, and logs all betray you
- **Docker Secrets (file-based)** -- one file per secret, mounted at /run/secrets/, invisible to inspection
- **The entrypoint-wrapper pattern** -- converting secret files to environment variables at startup
- **SOPS + age** -- encrypting secrets at rest so they're safe even in a git repo (advanced path)
- **Password manager CLI** -- pulling secrets from Bitwarden or 1Password at deploy time
- **Secret vs config** -- knowing what actually needs protection and what doesn't
- **File permissions** -- why `chmod 600` is your new best friend

### Prerequisites

You should have completed Modules 4 and 5. You need a running VPS with Docker and Docker Compose installed, and you should understand the "lethal trifecta" concept.

> **Self-check:** Can you SSH into your VPS, run `docker compose version`, and explain what the three legs of the lethal trifecta are? You're ready.

### Builds On

- **Module 4: Containers -- Your Apps in Boxes** -- you know Docker Compose, volumes, and how containers work
- **Module 5: The Lethal Trifecta** -- you understand why exposed secrets are dangerous; now we fix them

### What's Next

In **Module 7: Zero Open Ports -- Cloudflare Tunnel**, we'll tackle the "open ports" leg of the trifecta. Your secrets will be locked down; next, we make your server invisible to the internet entirely. Together, these two modules eliminate two-thirds of the lethal trifecta in a single afternoon.

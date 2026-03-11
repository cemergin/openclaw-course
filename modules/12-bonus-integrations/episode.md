# Episode 12: Power Ups -- GitHub, Gmail, Notion, and More

## Connecting Your AI Agent to the Rest of Your Digital Life

### In This Episode

Your OpenClaw bot is deployed, secured, monitored, and has a kill switch. It works. Now let's make it *useful*. This module is a pick-your-own-adventure through the integrations that turn a chat-based AI into a genuine personal assistant -- one that can push code to GitHub, read your newsletters, capture tasks in Notion, store files in Google Drive, and search the web on your behalf. Each integration is completely independent, so do the ones you care about and skip the rest. We'll apply the same security principles you've been learning all course (least privilege, scoped tokens, dedicated accounts) to every single one.

### Key Concepts

- **Fine-grained GitHub tokens** -- scoped to specific repos and permissions, not the all-access classic tokens
- **OAuth2 for Google APIs** -- the flow for Gmail, Drive, and Calendar (it's the same pattern, repeated)
- **The dedicated account pattern** -- isolating AI access from personal data with a purpose-built Gmail account
- **Prompt injection via email** -- the biggest AI-specific security risk, and why Gmail access requires extra paranoia
- **Notion integration tokens** -- explicit page sharing means your agent only sees what you allow
- **SearXNG vs Tavily** -- self-hosted private search vs API-based convenience
- **Token rotation** -- building the habit of expiring and replacing credentials on a schedule

### Prerequisites

You should have a fully deployed OpenClaw stack (Modules 6-9), with monitoring (Module 10) and a kill switch (Module 11) in place. You should be comfortable with Docker secrets and the principle of least privilege.

> **Self-check:** Can you message your WhatsApp bot and get a response? Can you explain why we use Docker file-based secrets instead of .env files? You're ready.

### Builds On

- **Module 6: Secrets Management** -- you'll store every new token as a Docker secret, not in .env
- **Module 5: The Lethal Trifecta** -- least privilege, scoped access, and security-first thinking guide every integration
- **Module 9: Full Docker Compose Deployment** -- you'll add new secrets and environment variables to your running stack
- **Module 11: The Kill Switch** -- if an integration misbehaves, you know how to shut things down fast

### What's Next

This is the final module. After this, you have a fully deployed, secured, monitored, kill-switch-equipped AI agent connected to the services you actually use. The course is done -- but your agent's journey is just beginning. Check the course wrap-up for ideas on what to explore next.

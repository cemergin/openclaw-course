# Episode 10: Power Ups -- GitHub, Gmail, Notion, and More

## Your Bot Is Running, Secured, Monitored, and Killable. Now Make It Useful.

### In This Episode

Your OpenClaw agent is deployed natively on a VPS, locked behind a Cloudflare Tunnel, secrets properly managed via SecretRef, monitored by Uptime Kuma, and equipped with a kill switch on your phone. Congratulations -- you've built the operational foundation that most hobby developers skip entirely.

But right now, your bot is a brain in a jar. It can think, but it can't *do* much beyond chatting. This module changes that. You'll connect OpenClaw to the services you actually use -- GitHub for code, Gmail for email, Notion for tasks, Google Drive for files -- turning it from "a chatbot I can message" into "an assistant that actually helps me get things done."

This is a pick-your-own-adventure module. Each integration is completely independent. Do the ones you care about, skip the rest, come back later for the ones you skipped. We'll apply the same security principles you've been learning all course -- least privilege, scoped tokens, dedicated accounts -- to every single one.

### Key Concepts

- **Fine-grained GitHub tokens** -- scoped to specific repos and permissions, not the all-access classic tokens
- **OAuth2 for Google APIs** -- the authorization flow for Gmail and Drive
- **The dedicated account pattern** -- isolating AI access from personal data with a purpose-built Gmail account
- **Prompt injection via email** -- the biggest AI-specific security risk when connecting email to your agent
- **Notion integration tokens** -- explicit page sharing means your agent only sees what you allow
- **Token rotation** -- building the habit of expiring and replacing credentials on a schedule
- **openclaw.json SecretRef** -- storing every new token as a file-based secret, referenced in config
- **openclaw channels add** -- the CLI command for adding new integration channels

### Prerequisites

You should have a fully deployed native OpenClaw stack (Modules 0-8), with monitoring and a kill switch (Module 9) in place. You should be comfortable with the SecretRef pattern and the principle of least privilege.

> **Self-check:** Can you message your bot via Telegram and get a response? Can you explain why we use SecretRef in `openclaw.json` instead of inline API keys? You're ready.

### Builds On

- **Module 7: Secrets Management** -- you'll store every new token as a file-based secret with SecretRef
- **Module 7: The Lethal Trifecta** -- least privilege, scoped access, and security-first thinking guide every integration
- **Module 6: Deploy Pipeline** -- you'll add new secrets and config to your running stack
- **Module 9: Monitoring + Kill Switch** -- if an integration misbehaves, you know how to detect it and shut things down

### What's Next

This is the final module. After this, you have a fully deployed, secured, monitored, kill-switch-equipped AI agent connected to the services you actually use. The course is done -- but your agent's journey is just beginning. Check the course wrap-up for ideas on what to explore next.

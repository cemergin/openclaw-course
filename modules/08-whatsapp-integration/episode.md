# Episode 8: WhatsApp -- The Real Integration

## Meta Business API, Webhooks, and Making It All Talk

### In This Episode

Telegram was the appetizer. WhatsApp is the main course -- and Meta does not make it easy. You'll navigate the Meta developer portal (which feels like it was designed by a committee that doesn't use its own product), set up a WhatsApp Business app, and configure webhooks that route through your Cloudflare Tunnel to reach OpenClaw on your locked-down server. Along the way, you'll learn how webhook signature verification actually works (HMAC-SHA256 -- it sounds scarier than it is), set up a phone number allowlist so only you can talk to your bot, and understand the complete message flow from your thumb hitting "send" to Claude's response landing in your chat. This is also where the security concepts from Module 5 stop being theory and start being real.

### Key Concepts

- **Meta Business Platform** -- the developer portal where WhatsApp integrations live (buckle up)
- **WhatsApp Business API** -- the official way to programmatically send and receive WhatsApp messages
- **Webhooks** -- Meta's way of telling your server "hey, a message just arrived"
- **HMAC-SHA256 signature verification** -- cryptographic proof that a webhook actually came from Meta
- **The full message lifecycle** -- phone to Meta to tunnel to OpenClaw to Claude and back again
- **Phone number allowlist** -- restricting your bot to only respond to approved numbers
- **Test vs production** -- the sandbox with 5 numbers vs the real deal with app review

### Prerequisites

You should have completed Modules 5, 6, and 7. You need a running VPS with Docker, properly managed secrets, a working Cloudflare Tunnel with a domain routed to your server, and UFW configured. You also need a WhatsApp account on your phone.

> **Self-check:** Can you open `https://openclaw.yourdomain.com` in a browser and get a response from your server (even if it's a 404 or health check)? That means your tunnel is working and you're ready.

### Builds On

- **Module 5: The Lethal Trifecta** -- webhook signature verification is defense in depth applied to incoming messages
- **Module 6: Secrets Management** -- you'll store WhatsApp credentials as Docker Secrets, not .env variables
- **Module 7: Cloudflare Tunnel** -- the tunnel you built is literally how Meta reaches your server; no tunnel, no webhooks

### What's Next

In **Module 9: Ship It -- Full Docker Compose Deployment**, you'll bring everything together -- VPS, Docker, secrets, tunnel, and WhatsApp -- into a single `docker-compose.yml`. The WhatsApp configuration you do here slots directly into that final compose file. You're one module away from the full stack.

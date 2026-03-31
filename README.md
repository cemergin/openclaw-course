# Deploy Your AI Agent — OpenClaw on the Cloud

A hands-on course that takes you from "I have Docker" to running your own AI agent on the cloud — properly secured, monitored, and ready for daily use.

You start locally: get [OpenClaw](https://openclaw.ai/) running in Docker on your laptop, connect Telegram, verify it works. Then you deploy the same Docker setup to a VPS via GitHub Actions, add Cloudflare Tunnel, monitoring, and a kill switch.

## Two Tracks

| Track | What You Get | Time |
|---|---|---|
| **Speed Run** (Module 0) | Working Telegram bot on your laptop tonight | 2-3 hours |
| **Full Course** (Modules 1-11) | Production-ready bot on a VPS, fully secured | 5-7 days |

## Modules

### Local — Get it working on your laptop

| # | Module | Time |
|---|---|---|
| 0 | **Speed Run — Your Bot Tonight** | 2-3h |
| 1 | What Are AI Agents (And Why Run Your Own)? | 30m |
| 2 | Docker on Your Machine | 1.5h |
| 3 | OpenClaw in Docker — Your Bot Works! | 1.5h |

### Deploy — Get it running on a server 24/7

| # | Module | Time |
|---|---|---|
| 4 | Your Computer in the Sky — AWS Lightsail | 1.5h |
| 5 | Git Push to Deploy — GitHub Actions | 1.5h |
| 6 | It's Alive — Verifying on the Instance | 1h |

### Production — Secure, monitor, extend

| # | Module | Time |
|---|---|---|
| 7 | The Lethal Trifecta — Security + Secrets | 2h |
| 8 | Zero Open Ports — Cloudflare Tunnel | 1.5h |
| 9 | WhatsApp and Beyond — Webhook Integrations | 2h |
| 10 | Monitoring + Kill Switch | 1.5h |
| 11 | Power Ups — GitHub, Gmail, Notion, and More | 2-3h |

## What You'll Learn

- **Docker** — Containers and Compose, locally and on a server
- **AI Agents** — What they are, how OpenClaw works, why self-hosting matters
- **Cloud Infrastructure** — Provision and manage a VPS on AWS Lightsail
- **CI/CD** — GitHub Actions for automatic deployment on git push
- **Web Security** — The "lethal trifecta" and how to defeat it
- **Secrets Management** — Docker Secrets, why .env files are dangerous
- **Networking** — Cloudflare Tunnel for zero-port-exposure
- **Monitoring** — Uptime Kuma, health checks, alert pipelines
- **Kill Switches** — Shut down a rogue AI agent from your phone

## Who This Is For

Tech-savvy developers and hobbyists who can navigate a terminal but haven't done much DevOps or cloud work yet.

## What You'll End Up With

A working OpenClaw instance running 24/7 on AWS that you can message from Telegram and WhatsApp, secured with:
- Zero open ports (Cloudflare Tunnel)
- Proper secrets management (Docker Secrets)
- Auto-deploy via GitHub Actions
- Monitoring with push notifications
- A kill switch bookmarked on your phone

## Each Module Includes

- **lesson.md** — Conversational teaching with diagrams and analogies
- **exercise.md** — Step-by-step guided walkthrough
- **challenge.md** — Independent practice with layered hints
- **starter/** — Templates and scaffolding to build from
- **solution/** — Completed references to check your work

## Prerequisites

- A computer with Docker Desktop installed (or willingness to install it)
- A credit card for AWS and API billing (~$20-40/mo total)
- A Telegram account (primary chat) and optionally WhatsApp
- Curiosity and a couple of evenings

## Getting Started

**Speed Run** (bot tonight): Start at `modules/00-speed-run/lesson.md`

**Full Course**: Start at `modules/01-ai-agents/lesson.md`

## Cost Estimate

| Item | Monthly |
|---|---|
| AWS Lightsail (4GB plan) | $20 |
| Anthropic API usage | $5-30 |
| Cloudflare (free plan) | $0 |
| **Total** | **~$25-50** |

## Built With

This course was generated using [tech-skill-builder](https://github.com/cemergin/tech-skill-builder) — a Claude Code plugin that creates hands-on technical courses with progressive exercises, spiral progression, and adaptive tutoring.

## License

This course content is open source. Use it, share it, learn from it.

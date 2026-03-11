# Deploy Your AI Agent — OpenClaw on the Cloud

A hands-on, week-long course that takes you from "I can `cd` and `ls`" to running your own AI agent on the cloud — properly secured, monitored, and ready for daily use.

You'll deploy [OpenClaw](https://openclaw.ai/) on AWS, connect it to WhatsApp via Cloudflare Tunnel, lock it down so only you can use it, and set up a kill switch you can trigger from your phone.

## Two Tracks

| Track | What You Get | Time |
|---|---|---|
| **Speed Run** (Module 0) | Working Telegram bot tonight | 2-3 hours |
| **Deep Dive** (Modules 1-12) | Production-ready WhatsApp bot, fully secured | 5-7 days |

## Modules

### Foundation

| # | Module | Time |
|---|---|---|
| 0 | **Speed Run — Your Bot Tonight** | 2-3h |
| 1 | What Are AI Agents (And Why Run Your Own)? | 45m |
| 2 | Your Computer in the Sky — AWS Lightsail | 1h |
| 3 | Remote Control — SSH and Linux Basics | 1.5h |
| 4 | Containers — Your Apps in Boxes (Docker) | 1.5h |
| 5 | The Lethal Trifecta (And How Not to Die) | 1.5h |

### Production

| # | Module | Time |
|---|---|---|
| 6 | Secrets Management — Not Just a .env File | 1.5h |
| 7 | Zero Open Ports — Cloudflare Tunnel | 1.5h |
| 8 | WhatsApp — The Real Integration | 2h |
| 9 | Ship It — Full Docker Compose Deployment | 2h |

### Mastery

| # | Module | Time |
|---|---|---|
| 10 | Is It Still Alive? — Monitoring and Alerts | 1h |
| 11 | The Kill Switch — Emergency Stop from Your Phone | 1h |
| 12 | Power Ups — GitHub, Gmail, Notion, and More | 2-3h |

## What You'll Learn

- **AI Agents** — What they are, how OpenClaw works, why self-hosting matters
- **Cloud Infrastructure** — Provision and manage a VPS on AWS Lightsail
- **Linux Administration** — SSH, users, permissions, services
- **Docker** — Containers, Compose, multi-service deployments
- **Web Security** — The "lethal trifecta" (open ports + exposed secrets + no monitoring) and how to defeat it
- **Secrets Management** — Docker Secrets, SOPS + age, why .env files are dangerous
- **Networking** — Cloudflare Tunnel for zero-port-exposure webhooks
- **Monitoring** — Health checks, Uptime Kuma, alert pipelines
- **Kill Switches** — 4 escalation levels to shut down a rogue AI agent from your phone

## Who This Is For

Tech-savvy developers and hobbyists who can navigate a terminal (`cd`, `ls`, basic commands) but haven't done much DevOps, server administration, or cloud security work yet. You don't need to be an expert in any of these topics — the course teaches everything from scratch.

## What You'll End Up With

A working OpenClaw instance running 24/7 on AWS that you can message from WhatsApp, secured with:
- Zero open ports (Cloudflare Tunnel)
- Proper secrets management (Docker Secrets)
- Monitoring with push notifications
- A kill switch bookmarked on your phone
- Bonus integrations (GitHub, Gmail, Notion, Google Drive, web search)

## Each Module Includes

- **lesson.md** — Conversational teaching with diagrams and analogies
- **exercise.md** — Step-by-step guided walkthrough
- **challenge.md** — Independent practice with layered hints
- **starter/** — Templates and scaffolding to build from
- **solution/** — Completed references to check your work

## Prerequisites

- A computer with a terminal you're comfortable using
- A credit card for AWS and API billing (~$15-20/mo total)
- A WhatsApp account (for the full course) or Telegram (for the Speed Run)
- Curiosity and a couple of evenings

## Getting Started

**Speed Run** (bot tonight): Start at `modules/00-speed-run/lesson.md`

**Deep Dive** (the full course): Start at `modules/01-ai-agents/lesson.md`

## Cost Estimate

| Item | Monthly |
|---|---|
| AWS Lightsail ($10 plan) | $10 |
| Claude / OpenAI API usage | $5-30 |
| Cloudflare (free plan) | $0 |
| **Total** | **~$15-40** |

## Built With

This course was generated using [tech-skill-builder](https://github.com/cemergin/tech-skill-builder) — a Claude Code plugin that creates hands-on technical courses with progressive exercises, spiral progression, and adaptive tutoring. The plugin handles course design, content generation, and interactive learning sessions.

## License

This course content is open source. Use it, share it, learn from it.

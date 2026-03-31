# Episode 0: Speed Run -- Your Bot Tonight

## In This Episode

You're going to go from zero to a working AI agent on your phone in a single evening. No servers, no cloud accounts, no SSH -- just Docker Desktop on your laptop, an OpenClaw container, and a Telegram bot. By the end, you'll message your bot from your phone and get an answer back from Claude. It runs on your machine, it's yours, and it works tonight.

## Key Concepts

- **OpenClaw** -- an open-source personal AI agent that runs on your own hardware
- **Docker** -- a way to run software in an isolated box (no messy installs on your system)
- **docker-compose** -- a file that describes which boxes to run and how they connect
- **Two-service pattern** -- an always-running gateway (port 18789) + an on-demand CLI for setup
- **API keys** -- passwords that let OpenClaw talk to Claude or GPT
- **Telegram bots** -- the fastest way to get a chat interface to your agent (long polling -- works locally, no tunnel needed)

## Prerequisites

You should be comfortable with basic terminal commands (`cd`, `ls`, `mkdir`). If you can open a terminal and navigate to a folder, you're good.

> **Self-check:** Can you open a terminal and type `ls` without panicking? You're ready.

## What's Next

If you finish this and want to understand *why* everything works (and make it production-ready with proper security, monitoring, and a kill switch you can trigger from your phone), continue to [Module 1: What Are AI Agents?](../01-ai-agents/episode.md). The full course (Modules 1-10) rebuilds everything you did tonight -- but properly, on a server that never sleeps.

**The pitch:** Your bot runs on your laptop. When you close the lid, it stops. The full course teaches you to put it on a server that runs 24/7.

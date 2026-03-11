# Episode 2: Your Computer in the Sky

## Provisioning a VPS on AWS Lightsail

### In This Episode

You're about to rent a computer that lives in a data center, runs 24/7, and never sleeps -- even when your laptop is closed. We'll walk through what a VPS actually is, compare the major cloud providers (spoiler: Lightsail wins on simplicity), and then click our way through setting one up. By the end, you'll have a running Ubuntu server with a static IP address, ready for SSH in the next module.

### Key Concepts

- **VPS (Virtual Private Server)** -- your rented computer in someone else's data center
- **Cloud providers** -- AWS Lightsail, Hetzner, DigitalOcean, and friends
- **Instance sizing** -- picking the right amount of CPU, RAM, and storage
- **Static IP** -- a permanent address so your server doesn't play musical chairs
- **Lightsail firewall** -- locking down what's allowed in before we even install anything

### Prerequisites

You should have completed Module 1 (What Are AI Agents) and have a basic understanding of what OpenClaw is and why we're self-hosting it.

**Self-check:** Can you explain, in one sentence, why your AI agent needs a server that's always on? If yes, you're ready.

You'll also need a credit card for AWS signup. The instance we're creating costs $10/month (with a free trial available for new accounts).

### Builds On

- **Module 1: What Are AI Agents** -- you know *what* we're deploying; now we need somewhere to put it

### What's Next

- **Module 3: Remote Control -- SSH and Linux Basics** -- your server is running, but how do you actually *use* it? Next up: connecting to it and learning your way around Linux

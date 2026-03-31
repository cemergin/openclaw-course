# Episode 4: Your Computer in the Sky

## VPS, SSH, Linux, Node.js, and the Hybrid Stack

### In This Episode

You're about to rent a computer that lives in a data center, runs 24/7, and never sleeps -- even when your laptop is closed. We'll walk through what a VPS actually is, set one up on AWS Lightsail for $5/month, connect to it over SSH, learn our way around Linux, install Node.js and OpenClaw natively, and install Docker for the lightweight support services. By the end of this module, you'll have a running Ubuntu server with OpenClaw installed, Docker ready for support services, and an SSH shortcut so connecting is as easy as typing `ssh openclaw`.

### Key Concepts

- **VPS (Virtual Private Server)** -- your rented computer in someone else's data center
- **AWS Lightsail** -- the simplest way to get a VPS on AWS ($5/mo, first 3 months free)
- **Static IP** -- a permanent address so your server doesn't play musical chairs
- **SSH key pairs** -- the public key (a lock) goes on the server, the private key stays on your machine
- **Linux filesystem** -- where things live: /home, /etc, /var
- **Users and permissions** -- why root is dangerous and dedicated users are safer
- **The hybrid approach** -- OpenClaw runs natively, support services run in Docker
- **Node.js 24** -- the runtime that powers OpenClaw on your server

### Prerequisites

You should have completed Modules 0-3 (OpenClaw running locally, config-as-code repo built). You need a credit card for AWS signup and a terminal application on your local machine.

**Self-check:** Do you have a config-as-code repo with `config/openclaw.json`, `workspace/SOUL.md`, and `docker-compose.yml`? Can you open a terminal? If yes, you're ready for the cloud.

### Builds On

- **Module 3: OpenClaw Local** -- you've got OpenClaw running locally and a config-as-code repo ready; now we need somewhere to run it 24/7

### What's Next

- **Module 5: Git Push to Deploy** -- your server is ready, but how do you get your files onto it without hand-editing? Next up: GitHub Actions for automated deployment

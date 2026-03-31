# Episode 2: Docker on Your Machine

## Containers -- The Magic Box That Makes Deployment Boring (In a Good Way)

### In This Episode

You already got Docker installed during the Speed Run. Now we're going to actually *understand* it. We'll explore what containers are, why they exist, and how Docker Compose lets you describe your entire application in a single file. By the end, you'll be running multi-service stacks and poking around inside containers like a pro.

### Key Concepts

- **Containers vs VMs vs bare metal** -- three ways to run software, one clear winner for our use case
- **Images vs containers** -- the recipe vs the cooked dish
- **Docker Compose** -- one YAML file to describe your entire stack, one command to start it all
- **Volumes** -- how data survives when containers die
- **Networks** -- how containers discover and talk to each other
- **Port mapping** -- connecting container ports to the outside world (and why `127.0.0.1:` matters)

### Prerequisites

You should have completed Module 0 (Speed Run) or Module 1. Docker should be installed on your machine.

**Self-check:** Run `docker --version` in your terminal. See a version number? You're good.

### Builds On

- **Module 0: Speed Run** -- Docker is already installed
- **Module 1: The Big Picture** -- you understand what we're building and why

### What's Next

In **Module 3: OpenClaw in Docker**, we'll take everything you learn here and use it to get OpenClaw running locally with Telegram. The Docker Compose skills from this module are the foundation for everything that follows.

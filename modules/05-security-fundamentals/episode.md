# Episode 5: The Lethal Trifecta (And How Not to Die)

## Security Fundamentals for Anyone Running a Server

### In This Episode

Your server is running. Docker is installed. Everything works. Here's the problem: so does everyone else's port scanner. In this episode, we're going to talk about the three things that get servers owned -- open ports, exposed secrets, and no monitoring -- and why having all three at once is basically handing your credit card to the internet. Then we'll actually fix two of them today (firewall and auto-updates), and build the security checklist you'll reference for every remaining module in this course.

### Key Concepts

- **The lethal trifecta** -- open ports + exposed secrets + no monitoring = guaranteed bad time
- **Attack surface** -- everything a hacker can probe, poke, or exploit on your server
- **Defense in depth** -- multiple layers of security, because no single layer is enough
- **Principle of least privilege** -- give the minimum access needed, nothing more
- **Security theater** -- things that look secure but aren't (changing port numbers, obscure URLs)
- **UFW firewall** -- your first real line of defense, blocking all unnecessary inbound traffic
- **Automatic security updates** -- patching vulnerabilities before attackers exploit them
- **Prompt injection** -- the AI-specific attack where crafted messages trick your agent into doing bad things

### Prerequisites

You should have completed Modules 3 and 4. You need a running VPS with SSH access, a dedicated `openclaw` user, and Docker installed.

> **Self-check:** Can you SSH into your server as the `openclaw` user and run `docker ps` without errors? You're ready.

### Builds On

- **Module 2: Your Computer in the Sky** -- you have a VPS with a static IP (which means it's findable)
- **Module 3: SSH and Linux Basics** -- you created a non-root user and understand permissions
- **Module 4: Containers** -- you know about port mapping, which is directly relevant to open ports

### What's Next

In **Module 6: Secrets Management**, we'll tackle the second leg of the trifecta -- exposed secrets. You'll learn why `.env` files are riskier than you think and implement proper Docker Secrets. The security mental model you build here is the foundation for every decision in that module.

# Your Computer in the Sky

## VPS, SSH, Linux Basics, and the Hybrid Install

---

Have you ever left your laptop running overnight so a download could finish? Or kept a script going while you slept? Now imagine a computer that *never* needs to sleep, never loses its internet connection, and sits in a climate-controlled building with redundant power and a network connection faster than anything you have at home.

That's what we're renting today. And it costs less than a fancy coffee per week.

## What Is a VPS, Really?

A **VPS** -- Virtual Private Server -- is a computer in a data center that you rent by the month. "Virtual" because the physical machine is shared with other renters (like apartments in a building), but your slice is completely isolated. You get your own operating system, your own storage, your own IP address. Nobody else can see your stuff, and you can't see theirs.

Think of it like this: buying a physical server is like buying a house. A VPS is like renting an apartment. You get your own space, your own keys, and you can decorate however you want -- but someone else handles the plumbing, the electricity, and the roof.

For our purposes, the VPS is where OpenClaw will live. It runs 24/7, so your AI agent is always available. You message it at 3am from your phone? The VPS is awake, processing your request, calling the Claude API, and sending back a response. Your laptop can be off. Your phone can be on airplane mode after sending. The VPS handles everything.

> **The Bigger Picture:** Every web service you use -- Gmail, Netflix, Slack -- runs on servers in data centers. What we're doing isn't exotic. We're just doing it ourselves instead of paying someone else's markup. That's the whole self-hosting philosophy.

## Why Lightsail

There are dozens of companies that will rent you a VPS -- DigitalOcean, Hetzner, Vultr, Linode. We're using AWS Lightsail for three reasons:

**1. Simplicity.** Lightsail is AWS's "just give me a server" product. Regular AWS (EC2) is like walking into a restaurant with a 47-page menu. Lightsail is the daily special. You pick a size, click create, and you're done.

**2. Predictable pricing.** With regular AWS, you can accidentally spin up resources that cost hundreds of dollars. Lightsail has flat monthly pricing. The $5 plan costs $5. Period.

**3. Free trial.** The first 3 months of the $5 plan are free. You're literally paying nothing while you learn.

> **Pro tip:** If you're not in the US or prefer European data centers, Hetzner is genuinely excellent and much cheaper for equivalent specs. The steps in this course will work on any Ubuntu VPS -- we're using Lightsail as the reference, but the concepts are universal.

## Picking the Right Size -- And Why $5 Is Enough

Here's where things changed from v1 of this course. We used to recommend the $20/month plan (4GB RAM) because OpenClaw's Docker onboarding process was memory-hungry. But we're not using Docker for OpenClaw anymore.

**The $5/month plan** (1 vCPU, 1GB RAM, 40GB SSD) is all we need. Here's the math:

| Component | RAM Usage | How It Runs |
| --- | --- | --- |
| OpenClaw (native) | ~200-400MB | Directly on the server via npm |
| Cloudflare Tunnel | ~30MB | Docker container |
| Uptime Kuma | ~50MB | Docker container |
| Kill switch | ~10MB | Docker container |
| **Total** | **~300-500MB** | **Well within 1GB** |

| Plan | Specs | Verdict |
| --- | --- | --- |
| **$5/mo** | **1 vCPU, 1GB RAM, 40GB SSD** | **The sweet spot. First 3 months free.** |
| $10/mo | 1 vCPU, 2GB RAM, 60GB SSD | More headroom. Nice but not necessary. |
| $20/mo | 2 vCPU, 4GB RAM, 80GB SSD | Overkill for this setup. |

## Why Native, Not Docker?

You might be wondering: "We just spent Module 3 learning Docker. Why aren't we running OpenClaw in Docker on the server?"

Great question. Here's the honest answer:

**OpenClaw's Docker image needs 4GB+ RAM to run its onboarding process.** A $5 VPS has 1GB. You'd need the $20/month plan just to run the Docker version -- that's $240/year instead of $60/year (or $0 for the first 3 months).

Running OpenClaw natively (installed directly via npm) uses less than 512MB of RAM. That fits comfortably on the $5 plan.

**Docker is still great for the support services** -- Cloudflare Tunnel, Uptime Kuma, and the kill switch. These are lightweight containers that barely sip memory. Docker gives us easy management, automatic restarts, and clean isolation for these services.

So that's our hybrid approach:
- **OpenClaw** runs natively (`npm i -g openclaw`, managed with `openclaw gateway start/stop`)
- **Support services** run in Docker (managed with `docker compose up -d`)
- **Best of both worlds:** low memory footprint, low cost, easy management

> **Mac Mini Alternative:** If you don't want a monthly bill at all, a Mac Mini ($479 one-time) makes an excellent always-on server. Run it headless on your home network, install OpenClaw natively, and it pays for itself in about 2 years compared to VPS hosting. The trade-off: you're responsible for your own uptime (power, internet, hardware failures). If your home internet goes down, your agent goes dark. A VPS in a data center doesn't have this problem.

## Static vs. Dynamic IPs

When you create a Lightsail instance, it gets an IP address. But that IP can *change* every time you stop and restart the instance. A **static IP** is a permanent address that stays the same no matter what. On Lightsail, static IPs are free as long as they're attached to a running instance. There's no reason not to use one.

## A Word About the Firewall

Lightsail instances come with a built-in firewall that allows HTTP (port 80) and HTTPS (port 443) by default. We're going to **remove those default rules and keep only SSH (port 22)**. The only way to reach your server from the internet will be through SSH, which requires your private key.

This is security-first thinking: start locked down, open things up only when you have a reason.

---

## SSH: The Lock and Key

Your server is sitting in a data center somewhere, humming along without a keyboard or monitor. So how do you type commands on a computer you can't touch?

**SSH** -- Secure Shell -- is your encrypted remote control. It uses **public-key cryptography**, which sounds intimidating but is actually elegant:

- **Public key** (the padlock) -- goes on the server. You can share it freely. It can only *lock* things (encrypt), not unlock them.
- **Private key** (the key) -- stays on *your* machine. Never leaves. Never shared. Never emailed. This is what proves you are you.

When you connect, the server sends a challenge encrypted with your public key. Your computer decrypts it with your private key. If the answer is correct, you're in. This all happens in milliseconds.

### Why Not Just Use Passwords?

Automated bots scan the internet 24/7, trying common username/password combinations on every server they find. Your VPS will start getting these attempts within *minutes* of going online. SSH keys are essentially passwords that are thousands of characters long and randomly generated -- impossible to brute force.

### The SSH Config Shortcut

Typing `ssh -i ~/.ssh/openclaw ubuntu@123.45.67.89` every time is tedious. SSH has a built-in way to create shortcuts using `~/.ssh/config` on your local machine:

```
Host openclaw
    HostName 123.45.67.89
    User ubuntu
    IdentityFile ~/.ssh/openclaw
    Port 22
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

After that, you just type `ssh openclaw` and you're on the server. The keepalive settings send a ping every 60 seconds so your connection doesn't drop when you step away.

---

## The Linux Filesystem: Where Things Live

Your server runs Ubuntu Linux. Everything starts from a single root directory: `/` (just a forward slash).

| Directory | What's in it | Why you care |
|-----------|-------------|--------------|
| `/home` | User home directories | Your `deploy` user's files live in `/home/deploy` |
| `/root` | Root user's home directory | Where you land when you SSH in as root |
| `/etc` | Configuration files | SSH config, system settings |
| `/var` | Variable data (logs, databases) | Docker stores its data here |
| `/tmp` | Temporary files | Cleared on reboot |
| `/usr` | User programs and libraries | Where installed software (including Node.js) ends up |

### Getting Around

```bash
pwd              # Print Working Directory -- where am I?
ls               # List files in current directory
ls -la           # List ALL files (including hidden), with details
cd /etc          # Change to the /etc directory
cd ~             # Go to your home directory
cd ..            # Go up one directory
```

Nothing exotic. The main difference from your laptop is that *you're navigating someone else's computer* -- and everything you do has real consequences on a live server.

---

## Users and Permissions: Why Root Is Dangerous

When you first SSH into your Lightsail instance, you're the `ubuntu` user (which has sudo/root powers). Root is the superuser -- it can read every file, kill every process, delete the entire filesystem.

That's exactly the problem. If something goes wrong while running as root, the blast radius is unlimited.

The fix: **create a dedicated user for deployment and run everything as that user.**

### The `deploy` User

We'll create a user specifically for deploying and running OpenClaw:

```bash
sudo adduser --disabled-password --gecos "" deploy
sudo usermod -aG docker deploy
```

The `--disabled-password` flag means no password login (SSH keys only). Adding the user to the `docker` group lets them run Docker commands without sudo.

### File Permissions: The Number System

Every file has three permission groups: owner, group, others. Each gets read (4), write (2), and execute (1):

```bash
chmod 600 secret-file     # Owner can read/write. Nobody else.
chmod 700 secret-dir      # Owner can read/write/enter. Nobody else.
chown deploy:deploy file  # Change ownership to the deploy user
```

The pattern `600` for secrets and `700` for directories is your go-to.

---

## Installing Node.js 24

OpenClaw runs on Node.js. We need a recent version -- Node.js 24 -- installed directly on the server.

```bash
curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
sudo apt install -y nodejs
```

That's two commands. The first adds the NodeSource repository (which has the latest Node.js versions -- Ubuntu's built-in repo is ancient). The second installs it.

Verify it worked:

```bash
node --version    # Should show v24.x.x
npm --version     # Should show 10.x.x or higher
```

## Installing OpenClaw

With Node.js in place, installing OpenClaw is one command:

```bash
npm i -g openclaw
```

The `-g` flag means "global" -- it installs OpenClaw as a system-wide command, not inside a specific project. After this, you can run `openclaw` from anywhere.

Verify:

```bash
openclaw --version
```

That's it. OpenClaw is installed. No Docker image to pull, no compose file to write, no 4GB of RAM needed. Just a clean native install that uses a fraction of the resources.

## Installing Docker (for Support Services Only)

We still need Docker -- not for OpenClaw itself, but for the support services we'll add in later modules (Cloudflare Tunnel, Uptime Kuma, kill switch). These are lightweight containers that play nicely with our 1GB of RAM.

```bash
# Install prerequisites
sudo apt update
sudo apt install -y ca-certificates curl gnupg

# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Verify it works
sudo docker run hello-world
```

After installation, Docker runs as a system service:

```bash
sudo systemctl enable docker     # Start on boot (usually already enabled)
```

> **Reminder:** Docker is here for the support services only. OpenClaw itself runs natively. This is intentional -- we keep the memory footprint low and the monthly bill at $5.

---

## Package Management: `apt`

Ubuntu uses `apt` to install software:

```bash
sudo apt update            # Refresh the list of available packages
sudo apt install htop -y   # Install a package (-y = yes to all prompts)
```

**Always run `apt update` before `apt install`**. The package list gets stale otherwise.

---

## Creating the Deploy User

The last piece: a dedicated user for running OpenClaw and managing deployments.

```bash
# Create the user
sudo adduser --disabled-password --gecos "" deploy

# Add to the docker group (for managing support services)
sudo usermod -aG docker deploy

# Create the project directory
sudo mkdir -p /home/deploy/openclaw
sudo chown -R deploy:deploy /home/deploy/openclaw

# Set up SSH access for the deploy user
sudo mkdir -p /home/deploy/.ssh
sudo cp /home/ubuntu/.ssh/authorized_keys /home/deploy/.ssh/
sudo chown -R deploy:deploy /home/deploy/.ssh
sudo chmod 700 /home/deploy/.ssh
sudo chmod 600 /home/deploy/.ssh/authorized_keys

# Set up OpenClaw config directory for the deploy user
sudo mkdir -p /home/deploy/.openclaw
sudo chown -R deploy:deploy /home/deploy/.openclaw
```

Now you can SSH in as the deploy user: `ssh deploy@YOUR_VPS_IP` (or update your SSH config to use `User deploy`).

---

## Avoiding Surprise Bills

Lightsail is designed to prevent bill shock. Your instance has a flat monthly rate with bandwidth included. But watch out for:

- **Stopped instances still cost money.** If you're done, *delete* the instance.
- **Unattached static IPs cost ~$3.60/month.** Always clean up.
- **Snapshots cost $0.05/GB/month.** Cheap but don't forget they exist.
- **The first 3 months are free** on the $5 plan. Set a calendar reminder for month 3.

The most important rule: if you stop using this setup, **delete everything**.

---

## What We Just Covered

- A VPS is a rented computer in a data center -- always on, always connected
- Lightsail is the simplest way to get a VPS on AWS, with predictable pricing
- The $5/month plan (1 vCPU, 1GB RAM) is enough because OpenClaw runs natively
- Native OpenClaw uses <512MB RAM; Docker OpenClaw needs 4GB+ -- that's why we go native
- SSH keys are your encrypted remote control -- never use passwords
- The SSH config shortcut lets you connect with just `ssh openclaw`
- Linux filesystem basics: where things live and how permissions work
- Node.js 24 powers OpenClaw; Docker powers the lightweight support services
- A dedicated `deploy` user limits the blast radius if something goes wrong

Time to actually do all of this. Head to the exercise.

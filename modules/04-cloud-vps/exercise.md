# Exercise: Launch Your Server, Connect, and Install Everything

## What We're Doing

We're creating an AWS account (if you don't have one), spinning up an Ubuntu server on Lightsail for $5/month, locking down the firewall, attaching a static IP, generating SSH keys, setting up an SSH shortcut, exploring Linux, installing Node.js and OpenClaw natively, installing Docker for support services, and creating a dedicated deploy user. That's a lot -- but every step is straightforward. By the end, you'll have a production-ready server with OpenClaw installed and waiting.

## Prerequisites

- A web browser
- A credit card (for AWS signup -- first 3 months free on the $5 plan)
- A phone number (for AWS verification)
- A terminal application on your local machine (Terminal on macOS, Windows Terminal on Windows)
- About 30-40 minutes

---

## Part 1: Create an AWS Account

*If you already have an AWS account, skip to Part 2.*

**Step 1.** Open your browser and go to [https://aws.amazon.com](https://aws.amazon.com). Click **Create an AWS Account** (top right).

**Step 2.** Enter your email address and choose an account name. "My OpenClaw Server" works fine. Click **Verify email address**.

**Step 3.** Check your email for a verification code. Enter it.

**Step 4.** Set a strong password. Save it in a password manager.

**Step 5.** Choose **Personal** for the account type. Fill in your contact information.

**Step 6.** Enter your credit card information. AWS won't charge you yet -- the $5 Lightsail plan is free for the first 3 months.

**Step 7.** Verify your phone number via call or SMS.

**Step 8.** Choose the **Basic (Free)** support plan.

**Step 9.** You should land on the AWS Console dashboard. The hard part is over -- that was mostly filling out forms.

---

## Part 2: Navigate to Lightsail and Create Your Instance

**Step 10.** Go directly to [https://lightsail.aws.amazon.com](https://lightsail.aws.amazon.com).

> **Pro tip:** Bookmark this URL. The main AWS console has about a thousand services. Lightsail has its own, cleaner interface.

**Step 11.** Click **Create instance**.

**Step 12.** Under **Instance location**, pick the region closest to you. If you're in Europe, pick Frankfurt or London. If you're in the US, us-east-1 (Virginia) is a solid default.

**Step 13.** Under **Pick your instance image**:
- Select **Linux/Unix** as the platform
- Select **OS Only**
- Select **Ubuntu 24.04 LTS**

We want a clean Ubuntu installation -- no pre-installed apps.

> **Why Ubuntu 24.04?** LTS means Long Term Support -- security updates for 5 years. It's the latest stable long-term release.

**Step 14.** Scroll down to **Choose your instance plan**. Select the **$5/month** plan (1 vCPU, 1GB RAM, 40GB SSD).

Yes, $5 is enough. OpenClaw runs natively and uses less than 512MB of RAM. The Docker-based install from v1 of this course needed 4GB, but we're smarter now.

> **Free for 3 months:** AWS gives you the first 3 months of the $5 Lightsail plan for free. After that, it's $5/month -- less than a streaming subscription.

**Step 15.** Under **Identify your instance**, name it something like `openclaw-01`. Keep it short and lowercase.

**Step 16.** Click **Create instance**.

**Step 17.** Wait 30-60 seconds. Your instance will show as "Pending" and then switch to "Running."

Somewhere in a data center, a computer just booted up, and it's yours.

---

## Part 3: Configure the Firewall

**Step 18.** Click on your instance name to open its detail page.

**Step 19.** Click the **Networking** tab.

**Step 20.** Scroll down to the **IPv4 Firewall** section. You should see:

| Application | Protocol | Port range |
| --- | --- | --- |
| SSH | TCP | 22 |
| HTTP | TCP | 80 |
| HTTPS | TCP | 443 |

**Step 21.** **Delete the HTTP rule.** Click the three dots next to the HTTP row and remove it.

**Step 22.** **Delete the HTTPS rule.** Same thing -- remove it.

**Step 23.** You should now have **only one firewall rule**:

| Application | Protocol | Port range |
| --- | --- | --- |
| SSH | TCP | 22 |

Your server is now invisible to the internet except for SSH. Every open port is a door -- we just closed two we don't need.

> **Also check IPv6:** If you see an IPv6 firewall section, delete the HTTP and HTTPS rules there too. Keep SSH only.

---

## Part 4: Attach a Static IP

**Step 24.** Still on the **Networking** tab, scroll to the **Public IPv4 address** section.

**Step 25.** Click **Attach static IP**.

**Step 26.** Name it `openclaw-ip` and click **Create and attach**.

**Step 27.** **Write down your static IP address.** You'll need it for every module going forward. It looks like `18.194.123.45`.

> **Pro tip:** Put this IP somewhere easy to find. A note on your phone, a sticky note on your monitor. You'll type it a lot.

---

## Part 5: Generate SSH Keys and Connect

### Step 28: Generate a key pair (on your LOCAL machine)

```bash
ssh-keygen -t ed25519 -C "openclaw-vps" -f ~/.ssh/openclaw
```

When it asks for a passphrase, either set one (more secure) or leave it blank (more convenient). For this course, either is fine.

### Step 29: Verify the key files

```bash
ls -la ~/.ssh/openclaw*
```

You should see:
- `~/.ssh/openclaw` -- your **private key**. Never share this.
- `~/.ssh/openclaw.pub` -- your **public key**. This goes on the server.

### Step 30: Check permissions on the private key

```bash
chmod 600 ~/.ssh/openclaw
```

SSH will refuse to use a private key if other users can read it.

### Step 31: Connect using the Lightsail default key

First, let's connect with the key Lightsail generated. Download it from the Lightsail console (Account > SSH keys) or find it wherever you saved it during account setup.

```bash
ssh -i ~/path/to/LightsailDefaultKey.pem ubuntu@YOUR_VPS_IP
```

Replace the path and IP with your actual values.

The first time you connect, you'll see:

```
The authenticity of host '123.45.67.89' can't be established.
Are you sure you want to continue connecting (yes/no)?
```

Type `yes`.

### Step 32: Confirm you're on the server

```bash
hostname
whoami
```

`hostname` should print your server's name (like `ip-172-26-1-42`). `whoami` should print `ubuntu`.

### Step 33: Add your new public key to the server

On your **local machine** (open a new terminal), display your public key:

```bash
cat ~/.ssh/openclaw.pub
```

Copy the entire output. Then on the **server** (your existing SSH session):

```bash
echo "PASTE_YOUR_PUBLIC_KEY_HERE" >> ~/.ssh/authorized_keys
```

Replace `PASTE_YOUR_PUBLIC_KEY_HERE` with the actual key.

### Step 34: Test the new key

Disconnect:

```bash
exit
```

Reconnect with your new key:

```bash
ssh -i ~/.ssh/openclaw ubuntu@YOUR_VPS_IP
```

If you see the server prompt, it worked.

---

## Part 6: Set Up the SSH Config Shortcut

On your **local machine**, create or edit the SSH config file:

```bash
nano ~/.ssh/config
```

(Or use any text editor you prefer.)

Add this block:

```
Host openclaw
    HostName YOUR_VPS_IP
    User ubuntu
    IdentityFile ~/.ssh/openclaw
    Port 22
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

Replace `YOUR_VPS_IP` with your actual static IP.

Set permissions:

```bash
chmod 644 ~/.ssh/config
```

Test it:

```bash
ssh openclaw
```

You should land on your server. No IP address, no key path, no username. Just `ssh openclaw`. That's it.

A starter template is provided in `starter/ssh-config-template` if you want to copy and customize it instead.

---

## Part 7: Explore the Linux Filesystem

Now that you're on the server, let's look around.

### Step 35: Basic navigation

```bash
ls /
```

This lists everything in the root directory. You should see `home`, `etc`, `var`, `root`, `tmp`, and others.

```bash
ls /home
```

You should see `ubuntu` -- that's the default user's home directory.

### Step 36: Check disk space and memory

```bash
df -h
```

Shows disk usage. Your Lightsail instance has about 40GB.

```bash
free -h
```

Shows memory (RAM). You should see about 1GB total. This is enough -- OpenClaw runs lean when installed natively.

> **Pro tip:** `df -h` and `free -h` are the quickest way to check if your server is running low on resources. You'll use them often.

### Step 37: Check what's running

```bash
systemctl list-units --type=service --state=running
```

You'll see SSH and some system services -- not much else. Your server is minimal. That's good.

---

## Part 8: Install Node.js 24

### Step 38: Add the NodeSource repository and install

```bash
curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
sudo apt install -y nodejs
```

### Step 39: Verify Node.js

```bash
node --version
npm --version
```

You should see Node.js 24.x.x and npm 10.x.x or higher.

---

## Part 9: Install OpenClaw

### Step 40: Install OpenClaw globally

```bash
sudo npm i -g openclaw
```

### Step 41: Verify OpenClaw

```bash
openclaw --version
```

You should see the version number. That's it -- OpenClaw is installed on your server. No Docker image, no 4GB RAM requirement, no compose file. Just a clean, lightweight native install.

---

## Part 10: Install Docker (for Support Services)

Docker isn't for OpenClaw itself -- it's for the lightweight support services we'll add later (Cloudflare Tunnel, Uptime Kuma, kill switch).

### Step 42: Install prerequisites

```bash
sudo apt update
sudo apt install -y ca-certificates curl gnupg
```

### Step 43: Add Docker's official repository

```bash
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

### Step 44: Install Docker

```bash
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### Step 45: Verify Docker works

```bash
sudo docker run hello-world
```

You should see "Hello from Docker!" and a message confirming the installation is working.

### Step 46: Check Docker Compose is available

```bash
docker compose version
```

You should see a version number (like `Docker Compose version v2.x.x`).

### Step 47: Enable Docker to start on boot

```bash
sudo systemctl enable docker
```

---

## Part 11: Create the Deploy User

### Step 48: Create the user

```bash
sudo adduser --disabled-password --gecos "" deploy
```

### Step 49: Add to the docker group

```bash
sudo usermod -aG docker deploy
```

This lets the `deploy` user run Docker commands without `sudo`.

### Step 50: Create the project and config directories

```bash
sudo mkdir -p /home/deploy/openclaw
sudo mkdir -p /home/deploy/.openclaw
sudo mkdir -p /home/deploy/.openclaw/workspace
sudo chown -R deploy:deploy /home/deploy/openclaw
sudo chown -R deploy:deploy /home/deploy/.openclaw
```

The `~/openclaw/` directory is where your config-as-code repo will be cloned. The `~/.openclaw/` directory is where OpenClaw reads its configuration from.

### Step 51: Set up SSH access for the deploy user

```bash
sudo mkdir -p /home/deploy/.ssh
sudo cp /home/ubuntu/.ssh/authorized_keys /home/deploy/.ssh/
sudo chown -R deploy:deploy /home/deploy/.ssh
sudo chmod 700 /home/deploy/.ssh
sudo chmod 600 /home/deploy/.ssh/authorized_keys
```

### Step 52: Test SSH as the deploy user

From your **local machine**, update your SSH config:

```bash
nano ~/.ssh/config
```

Change `User` from `ubuntu` to `deploy`:

```
Host openclaw
    HostName YOUR_VPS_IP
    User deploy
    IdentityFile ~/.ssh/openclaw
    Port 22
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

Test it:

```bash
ssh openclaw
```

Run `whoami` -- it should say `deploy`. Run `docker ps` -- it should work without sudo (you may need to log out and back in for the docker group to take effect).

Run `openclaw --version` -- it should show the version. The deploy user can run OpenClaw.

### Step 53: Fill in your server info

Open `starter/server-info.txt` and fill in all the values. Keep this file handy -- you'll reference it throughout the course.

---

## What Just Happened?

Take a breath. You just did a lot:

1. **Created an AWS account** -- your gateway to cloud services
2. **Launched a Lightsail instance** -- a $5/mo Ubuntu server running 24/7 (free for 3 months)
3. **Locked down the firewall** -- SSH only, no HTTP/HTTPS
4. **Attached a static IP** -- a permanent address that won't change
5. **Generated SSH keys** -- your own cryptographic identity for this server
6. **Set up an SSH shortcut** -- `ssh openclaw` gets you on the server instantly
7. **Explored the Linux filesystem** -- you know where things live
8. **Installed Node.js 24** -- the runtime that powers OpenClaw
9. **Installed OpenClaw natively** -- lightweight, fast, <512MB RAM
10. **Installed Docker** -- for support services only (tunnel, monitoring, kill switch)
11. **Created a deploy user** -- a dedicated, limited user for running your AI agent

Your server is ready. OpenClaw is installed. Docker is standing by for support services. A deploy user is waiting. Next module: we'll set up GitHub Actions so pushing code automatically deploys your configuration to this server.

Your monthly cost: **$0/month** for the first 3 months, then **$5/month**. The static IP is free.

# Exercise: Build Your Bot Tonight

## What We're Doing

We're going from zero to a working Telegram bot powered by Claude, running on a cloud server you control. Every click, every command -- it's all here. Follow along and you'll have a working AI agent by the time you finish your coffee (or beer, no judgment).

## What You'll Need

- A laptop with a terminal (Terminal on Mac, PowerShell on Windows, or any Linux terminal)
- A credit card for AWS (you won't be charged -- 3-month free tier)
- A Telegram account on your phone
- About 2 hours of uninterrupted time

---

## Part 1: Create Your Cloud Server (~15 minutes)

### Step 1: Create an AWS Account

If you already have an AWS account, skip to Step 2.

1. Go to [aws.amazon.com](https://aws.amazon.com/) and click **Create an AWS Account**
2. Enter your email, set a password, and choose an account name
3. Enter your credit card info (required, but we're using the free tier)
4. Complete phone verification
5. Choose the **Basic Support (Free)** plan

> **Don't panic** about the credit card. Lightsail has a flat $5/month price, and the first 3 months are free on the smallest plan. There are no surprise charges. This isn't one of those AWS horror stories.

### Step 2: Launch a Lightsail Instance

1. Go to [lightsail.aws.amazon.com](https://lightsail.aws.amazon.com/)
2. Click **Create instance**
3. Choose your settings:
   - **Region:** Pick one close to you (it affects latency, but for a chat bot, anything works)
   - **Platform:** Linux/Unix
   - **Blueprint:** OS Only --> **Ubuntu 22.04 LTS**
   - **Instance plan:** $5 USD/month (1 GB RAM, 1 vCPU, 40 GB SSD)
     - Look for the "First 3 months free" badge
   - **Instance name:** `openclaw` (or whatever you like)
4. Click **Create instance**

Your server will take about 60 seconds to start. You'll see it go from "Pending" to "Running."

> **What just happened?** AWS just created a virtual computer for you in a data center. It's running Ubuntu Linux, it has its own IP address, and it's on 24/7. You're renting it for $5/month (free for now).

### Step 3: Get Your Server's IP Address

1. Click on your instance name (`openclaw`) in the Lightsail dashboard
2. Look for the **Public IP** address -- it looks something like `54.123.45.67`
3. Write this down or copy it somewhere. You'll need it in a minute.

### Step 4: Download Your SSH Key

1. On your instance page, go to the **Networking** tab (or look at the main Lightsail page)
2. Actually -- Lightsail makes this easier. Go to **Account** (top-right menu) --> **SSH Keys**
3. Click **Download** next to the default key for your region
4. Save the file (it'll be called something like `LightsailDefaultKey-us-east-1.pem`)
5. Note where you saved it (probably `~/Downloads/`)

> **What's this file?** It's your SSH key -- think of it as a special password file that lets you log into your server. Don't share it, don't lose it, don't post it on social media.

---

## Part 2: Connect to Your Server (~5 minutes)

### Step 5: Set Key Permissions (Mac/Linux)

Open your terminal and run:

```bash
chmod 400 ~/Downloads/LightsailDefaultKey-*.pem
```

This tells your computer "only I can read this file." SSH is paranoid (in a good way) and refuses to use key files that other users could read.

> **Windows users:** If you're using PowerShell, you may need to right-click the .pem file --> Properties --> Security --> adjust permissions. Or just use the Lightsail browser-based SSH (click the terminal icon on your instance in the dashboard) to skip this entirely.

### Step 6: SSH Into Your Server

Replace `YOUR_IP` with the IP address from Step 3:

```bash
ssh -i ~/Downloads/LightsailDefaultKey-*.pem ubuntu@YOUR_IP
```

**Before you hit enter:** what do you think will happen?

You should see something like:

```
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-1028-aws x86_64)
...
ubuntu@ip-172-26-1-100:~$
```

That `ubuntu@ip-...` prompt means you're IN. Every command you type now runs on your cloud server, not your laptop. Wild, right?

> **If it asks "Are you sure you want to continue connecting?"** type `yes` and press Enter. This happens the first time you connect to any new server. It's SSH asking you to trust this server's identity.

> **Pro tip:** You can also use Lightsail's built-in browser terminal. On your instance page, click the orange terminal icon. No SSH key needed -- it connects through your browser. Great as a backup, but learning SSH is worth it.

### Step 7: Quick Sanity Check

Let's make sure your server is alive and well:

```bash
cat /etc/os-release | head -2
```

You should see:

```
PRETTY_NAME="Ubuntu 22.04.x LTS"
NAME="Ubuntu"
```

You're on an Ubuntu server in the cloud. Let's install some stuff.

---

## Part 3: Install OpenClaw (~10 minutes)

### Step 8: Update the System

First, let's make sure everything is up to date:

```bash
sudo apt update && sudo apt upgrade -y
```

This downloads the latest package lists and upgrades any outdated software. It'll take a minute or two.

### Step 9: Install Node.js

OpenClaw runs on Node.js. Let's install it:

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
```

Verify it worked:

```bash
node --version
npm --version
```

You should see version numbers (Node 20.x and npm 10.x or similar). If you see "command not found," something went wrong -- re-run the install commands above.

### Step 10: Install OpenClaw

Here's the moment of truth:

```bash
curl -fsSL https://openclaw.ai/install.sh | bash
```

Alternatively, if you prefer npm:

```bash
npm i -g openclaw
```

Verify it installed:

```bash
openclaw --version
```

You should see a version number. OpenClaw is on your server.

> **What just happened?** You downloaded and installed OpenClaw globally on your server. It's now available as a command you can run from anywhere.

---

## Part 4: Get Your API Keys (~10 minutes)

OpenClaw needs an AI brain. You'll get an API key from Claude (Anthropic) or OpenAI -- or both. Claude is recommended, but either works.

### Step 11: Get a Claude API Key (Recommended)

1. Go to [console.anthropic.com](https://console.anthropic.com/)
2. Sign up or log in
3. Go to **Settings** --> **API Keys** --> **Create Key**
4. Give it a name like "openclaw"
5. Copy the key -- it starts with `sk-ant-...`
6. **Important:** Save this key somewhere safe (a notes app, password manager, whatever). You won't be able to see it again after you close this page.
7. Go to **Plans & Billing** and add a payment method (pay-as-you-go)

> **How much will this cost?** For personal chat use, expect $1-5/month. Claude charges per token (roughly per word). A typical back-and-forth conversation costs fractions of a cent. You'd have to work really hard to spend $20 in a month.

### Step 11b: Get an OpenAI API Key (Alternative)

If you prefer GPT over Claude:

1. Go to [platform.openai.com](https://platform.openai.com/)
2. Sign up or log in
3. Go to **API Keys** --> **Create new secret key**
4. Copy the key (starts with `sk-...`)
5. Add billing info under **Settings** --> **Billing**

### Step 12: Keep Your Key Handy

You'll need to paste your API key in a few minutes during OpenClaw setup. Keep the tab open or paste it into a temporary note.

---

## Part 5: Create Your Telegram Bot (~5 minutes)

### Step 13: Talk to the BotFather

1. Open Telegram on your phone (or desktop app)
2. Search for **@BotFather** (it has a blue checkmark -- make sure it's the real one)
3. Tap **Start** or send `/start`
4. Send `/newbot`

### Step 14: Name Your Bot

BotFather will ask you two questions:

1. **"What name do you want for your bot?"** -- This is the display name. Pick anything fun:
   - `My OpenClaw`
   - `Jarvis`
   - `That AI Thing I Built`
   - Whatever makes you smile

2. **"Choose a username for your bot"** -- This must end in `bot`. For example:
   - `my_openclaw_bot`
   - `jarvis_personal_bot`
   - `cemergin_ai_bot`

### Step 15: Copy Your Bot Token

BotFather will respond with something like:

```
Done! Congratulations on your new bot. You will find it at t.me/my_openclaw_bot.

Use this token to access the HTTP API:
123456789:ABCdefGHIjklMNOpqrsTUVwxyz

Keep your token secure and store it safely.
```

Copy that token (the long string with the colon in the middle). You'll need it in the next step.

> **What just happened?** You created a Telegram bot. It exists now -- you can search for it in Telegram. It just doesn't do anything yet because there's nothing behind it. That's about to change.

---

## Part 6: Wire Everything Together (~10 minutes)

### Step 16: Run OpenClaw Onboarding

Switch back to your SSH terminal (the one connected to your server) and run:

```bash
openclaw onboard
```

This starts an interactive setup wizard. It'll ask you questions -- here's what to expect:

1. **AI Provider:** Choose Claude (Anthropic) or OpenAI
2. **API Key:** Paste the key you got in Step 11
3. **Chat integration:** Choose Telegram
4. **Telegram Bot Token:** Paste the token from Step 15
5. Follow any additional prompts (model selection, name, etc.)

> **Pro tip:** When pasting into an SSH terminal, use `Ctrl+Shift+V` (Linux) or `Cmd+V` (Mac). Right-click also works in many terminals.

### Step 17: Start OpenClaw

After onboarding completes, start OpenClaw:

```bash
openclaw start
```

You should see output indicating it's running and connected to Telegram. Look for something like "Telegram bot connected" or "Listening for messages."

> **If something goes wrong:** Check the output for error messages. The most common issues are:
> - **Invalid API key** -- double-check you copied the whole thing, no extra spaces
> - **Invalid Telegram token** -- same thing, check for typos
> - **Port already in use** -- run `openclaw stop` first, then `openclaw start`

---

## Part 7: The Moment of Truth (~1 minute)

### Step 18: Send Your First Message

1. Open Telegram on your phone
2. Search for your bot's username (the one ending in `_bot`)
3. Tap **Start**
4. Type a message. Anything. Here are some ideas:
   - "Hello! Are you alive?"
   - "What's the meaning of life?"
   - "Explain quantum computing like I'm five"
   - "Write me a haiku about cloud servers"

**Before you send it:** take a breath. You built a cloud server, installed an AI agent, created a bot, and wired them together. That message is about to travel from your phone, through Telegram's servers, to a computer you rented in the cloud, through Claude's API, and back. All in a few seconds.

Now send it.

### Step 19: Wait for the Response

Watch your Telegram chat. Within a few seconds, you should see your bot typing... and then a response appears.

If you're watching your SSH terminal at the same time, you might see logs showing the message being received and processed.

**It works.**

You just built a personal AI agent that runs on your own server. It's running right now, even if you close your laptop. You can message it from bed, from the subway, from another country. It's yours.

---

## Part 8: Keep It Running (~5 minutes)

### Step 20: Run in the Background

Right now, if you close your SSH terminal, OpenClaw stops. Let's fix that:

```bash
# Stop the current instance first
openclaw stop

# Start it in the background using nohup
nohup openclaw start > ~/openclaw.log 2>&1 &
```

Now you can close your terminal and it'll keep running.

> **What's nohup?** It stands for "no hangup" -- it tells the process to keep running even when you disconnect. The `> ~/openclaw.log 2>&1 &` part sends all output to a log file and runs it in the background.

To check if it's still running later:

```bash
# Check the process
ps aux | grep openclaw

# Check the logs
tail -20 ~/openclaw.log
```

To stop it:

```bash
openclaw stop
# or if that doesn't work:
pkill -f openclaw
```

### Step 21: Set It to Start on Boot (Optional)

If your server reboots, OpenClaw won't auto-start with the `nohup` approach. For tonight, that's fine. The full course (Module 9) sets this up properly with Docker and auto-restart policies.

If you want a quick fix:

```bash
# Add to crontab
(crontab -l 2>/dev/null; echo "@reboot cd /home/ubuntu && nohup openclaw start > ~/openclaw.log 2>&1 &") | crontab -
```

---

## What Just Happened?

Let's recap what you built:

```
Your phone (Telegram)
  --> Telegram servers (relay)
    --> AWS Lightsail VPS ($5/mo, running 24/7)
      --> OpenClaw (your AI agent)
        --> Claude API (the brain)
          --> Response flows back to your phone
```

You now have:
- A cloud server running Ubuntu, accessible via SSH
- OpenClaw installed and configured
- A Telegram bot connected to Claude
- An AI agent you can message from your phone, 24/7

**What you don't have (yet):**
- Proper security (firewall, dedicated user, encrypted secrets)
- Docker containers (clean, isolated, easy to update)
- WhatsApp integration (requires Cloudflare Tunnel)
- Monitoring (know when things break)
- A kill switch (emergency stop from your phone)

That's what the full course (Modules 1-12) is for. But tonight? Tonight you have a working bot. Enjoy it.

---

## Troubleshooting

**"Permission denied" when SSHing:**
- Make sure you ran `chmod 400` on the .pem file
- Make sure you're using `ubuntu@YOUR_IP` (not `root@`)
- Make sure the IP address is correct (check Lightsail dashboard)

**"Connection refused" when SSHing:**
- Your instance might still be starting. Wait 30 seconds and try again
- Check the Lightsail dashboard -- is the instance "Running"?

**OpenClaw won't start:**
- Run `openclaw --version` to verify it's installed
- Check `node --version` -- you need Node.js 18+
- Look at the error message carefully -- it usually tells you what's wrong

**Bot doesn't respond to messages:**
- Check the logs: `tail -50 ~/openclaw.log`
- Verify your Telegram token is correct: run `openclaw onboard` again
- Make sure OpenClaw is actually running: `ps aux | grep openclaw`
- Check your API key has billing enabled (Claude requires a payment method)

**"Insufficient funds" or API errors:**
- Make sure you've added billing info to your Claude/OpenAI account
- Check your API dashboard for any error messages

**Everything else:**
- Check the [OpenClaw docs](https://openclaw.ai)
- The full course (starting with Module 1) covers everything in much more detail

---

## Try This (Optional Experiments)

Now that your bot is working, play with it:

- [ ] Ask it something you'd normally Google
- [ ] Ask it to write code in your favorite language
- [ ] Ask it to explain a concept you've been struggling with
- [ ] Ask it to roleplay as a character
- [ ] Ask it what it knows about itself (it should mention OpenClaw)
- [ ] Send it a really long message and see how it handles it
- [ ] Ask it to remember something, then ask about it in a new message (test its memory)

When you're done playing, head to the [challenge](challenge.md) for some fun customization ideas.

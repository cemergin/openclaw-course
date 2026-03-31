# Exercise: Bring OpenClaw to Life on Your VPS

## What We're Doing

You're going to SSH into your VPS, verify all the deployed files are in the right places, run the diagnostic check, start the OpenClaw gateway, peek at the dashboard through an SSH tunnel, send a Telegram message and get a response, and then experience the payoff: close your laptop, send another message, and confirm your AI agent works without you. This is the victory lap.

## Prerequisites

- Module 5 completed (config deployed to VPS via GitHub Actions)
- Your Anthropic API key (from [console.anthropic.com](https://console.anthropic.com))
- Your Telegram bot token (from an earlier module -- wherever you set up the bot)
- SSH access to your VPS (`ssh openclaw`)
- About 15-20 minutes

---

## Step 1: SSH In and Verify the Deployment

Connect to your VPS:

```bash
ssh openclaw
```

### Check the repo is cloned

```bash
ls -la ~/openclaw/
```

You should see your config-as-code repo files: `config/`, `workspace/`, `docker-compose.yml`, `.github/`.

### Check OpenClaw config is in place

```bash
cat ~/.openclaw/openclaw.json
```

You should see your JSON5 configuration file. This was copied from `~/openclaw/config/openclaw.json` by the deploy workflow.

### Check workspace files are in place

```bash
ls -la ~/.openclaw/workspace/
cat ~/.openclaw/workspace/SOUL.md
```

You should see your SOUL.md (and IDENTITY.md if you have one, plus any skills/). These are the files that define your agent's personality.

If any of these files are missing, go back to Module 5 and make sure the deploy workflow ran successfully. You can also manually trigger it from the GitHub Actions tab.

---

## Step 2: Run the Doctor Check

Before starting anything, let the diagnostic tool validate your setup:

```bash
openclaw doctor
```

This checks everything: Node.js version, configuration validity, workspace files, API keys, network connectivity. Read the output carefully.

**If everything is green:** Move to Step 3.

**If something is red:** The doctor will tell you exactly what's wrong. Common fixes:

- **Missing API key** -- Set it with `openclaw config set anthropic_api_key YOUR_KEY_HERE`
- **Missing Telegram token** -- Set it with `openclaw config set telegram_bot_token YOUR_TOKEN_HERE`
- **Invalid config** -- Check `~/.openclaw/openclaw.json` for syntax errors
- **Missing workspace files** -- Re-run the deploy workflow or manually copy files

> **About secrets:** Your API key and Telegram token are NOT in your git repo (they're in `.gitignore`). You need to set them directly on the server the first time. After that, they persist across deploys because they're stored in `~/.openclaw/openclaw.json` on the server, and the deploy workflow copies your repo's config on top of it. If your repo config doesn't include the secrets (which it shouldn't!), the existing values on the server are preserved. Alternatively, set them with `openclaw config set` which writes directly to the server's config.

---

## Step 3: Start the OpenClaw Gateway

Deep breath. This is the moment.

```bash
openclaw gateway start
```

You should see a confirmation that the gateway is starting up on port 18789.

Check the status:

```bash
openclaw gateway status
```

You should see that the gateway is running. If it shows as stopped or crashed, check what went wrong:

```bash
openclaw doctor
```

Common issues:
- **Port already in use** -- Something else is on port 18789. Check with `sudo lsof -i :18789`
- **Missing API key** -- The gateway needs your Anthropic API key to start
- **Permission denied** -- Make sure you're the `deploy` user

---

## Step 4: Peek at the Dashboard (Optional)

Let's verify the dashboard is accessible through an SSH tunnel. On your **local machine** (not the server), open a new terminal and run:

```bash
ssh -L 18789:127.0.0.1:18789 openclaw
```

While this SSH session is open, open your browser and go to:

```
http://127.0.0.1:18789/
```

You should see the OpenClaw dashboard. Take a quick look around -- check the status, see the configuration. This is where you can monitor your agent's activity.

When you're done, close the browser tab. You can close the tunnel SSH session too -- the gateway keeps running on the server regardless.

> **Note:** The dashboard is a nice-to-have, not a requirement. Everything you need for daily operations is available through the CLI.

---

## Step 5: Send a Telegram Message -- First Test

Open Telegram on your phone. Find your bot (the one you created with @BotFather).

Send a simple message:

> Hey, are you there?

Now check the gateway status on your VPS:

```bash
openclaw gateway status
```

**Check your phone.** If you see a response -- congratulations. Your AI agent is running on your own server.

If you don't see a response, troubleshoot:

1. **Run the doctor** -- `openclaw doctor` -- check for any red items
2. **Check the gateway** -- `openclaw gateway status` -- is it actually running?
3. **API key** -- Did you set the Anthropic API key? `openclaw config get anthropic_api_key`
4. **Telegram token** -- Is the bot token correct? `openclaw config get telegram_bot_token`
5. **Network** -- Can the server reach the APIs? `curl -s https://api.anthropic.com`

---

## Step 6: The Big Payoff -- Close Your Laptop

This is the moment that makes everything worth it.

1. **Close your laptop lid.** Seriously. Shut it.
2. **Pick up your phone.**
3. **Send another Telegram message to your bot.** Try something like:

   > What time is it? Also, tell me a joke.

4. **Wait a few seconds.**
5. **Your bot responds.**

Your laptop is asleep. The VPS is awake. OpenClaw processed your message, called Claude, and sent the response through Telegram -- all without your laptop being involved.

That's what "always on" means. That's what we built.

---

## Step 7: Learn the Daily Operations

Open your laptop back up. SSH in again:

```bash
ssh openclaw
```

Practice each of these commands:

### Check gateway status

```bash
openclaw gateway status
```

### Restart the gateway (e.g., after changing config)

```bash
openclaw gateway restart
```

### Run diagnostics

```bash
openclaw doctor
```

### Check or change a config value

```bash
openclaw config get
openclaw config get model
```

### Check support services

```bash
cd ~/openclaw
docker compose ps
```

### View support service logs

```bash
cd ~/openclaw
docker compose logs -f
```

Press `Ctrl+C` to stop watching (this doesn't stop the services).

### Check resource usage

```bash
free -h    # Memory
df -h /    # Disk
```

On a $5 instance running native OpenClaw, you should see well under 512MB of RAM used and plenty of disk space.

---

## Step 8: Verify Restart Survival

Let's make sure your agent comes back after a restart:

```bash
# Restart the gateway
openclaw gateway restart

# Check it's running
openclaw gateway status
```

Send another Telegram message. It should still work.

Now let's check the support services survive too:

```bash
cd ~/openclaw
docker compose restart

# Wait a few seconds
docker compose ps
```

Everything should be back up.

---

## What Just Happened?

Let's take stock:

1. **You verified the deployment** -- config and workspace files are where they need to be
2. **You ran the doctor** -- diagnostics confirmed your setup is healthy
3. **You started the gateway** -- OpenClaw is running natively on your VPS
4. **You peeked at the dashboard** -- through a secure SSH tunnel
5. **You sent your first message** -- and got a response from Claude through Telegram
6. **You closed your laptop** -- and the bot kept working (this is the whole point!)
7. **You learned daily operations** -- a handful of CLI commands, no Docker needed for OpenClaw
8. **You verified restart survival** -- your agent comes back after restarts

Your AI agent is live. It's running natively on a server you provisioned, deployed via a pipeline you built, and it responds to your messages 24/7. That's a real deployment. And it costs $5/month (or $0 for the first 3 months).

---

## Try This (Optional Experiments)

**Experiment 1: Change the personality.** On your local machine, edit `workspace/SOUL.md` to add a new instruction (like "Always end responses with a fun fact"). Push to git. Wait for the deploy. Send a Telegram message and see if the new personality takes effect.

**Experiment 2: Monitor memory over time.** SSH in and run `watch free -h` while you send a few Telegram messages. Watch how memory spikes during processing and settles back down. On the native install, you should see comfortably less than 512MB used.

**Experiment 3: Test from different networks.** Send a Telegram message from your phone on WiFi, then switch to mobile data and send another. Both should work -- Telegram handles the routing, and your VPS is always accessible.

**Experiment 4: Check what's on port 18789.** Run `curl http://127.0.0.1:18789/` from the server itself. You should see the dashboard HTML or a status response. Now try from your local machine without the SSH tunnel -- it should fail (because the firewall blocks it). That's security working as intended.

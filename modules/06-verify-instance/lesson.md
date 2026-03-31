# It's Alive -- Verifying on the Instance

## Gateway Startup, Doctor Checks, and Daily Operations

---

## From Files to a Running Agent

You've got config files on your server. OpenClaw is installed. That's like having a recipe on the kitchen counter -- nothing is cooked yet. In this module, we bring everything to life.

The jump from "files deployed" to "working AI agent" involves three things: verifying the configuration, starting the gateway, and confirming it actually works. Let's talk about each.

## The OpenClaw Gateway

In the Docker world, you'd run `docker compose up -d` and everything lives inside a container. In our native setup, OpenClaw runs as a **gateway** -- a long-running process that sits on port 18789, receives messages from Telegram (or other integrations), processes them through Claude, and sends back responses.

The gateway is managed with simple CLI commands:

| Command | What it does |
|---|---|
| `openclaw gateway start` | Start the gateway (runs in background) |
| `openclaw gateway stop` | Stop the gateway gracefully |
| `openclaw gateway restart` | Stop then start (useful after config changes) |
| `openclaw gateway status` | Check if the gateway is running |

That's it. No `docker exec`, no compose files, no container IDs. Just clean, direct commands.

## openclaw doctor: Your Built-In Diagnostic

Before you start the gateway, OpenClaw has a diagnostic command that checks everything:

```bash
openclaw doctor
```

This validates:
- Node.js version (is it new enough?)
- OpenClaw configuration (is `~/.openclaw/openclaw.json` valid?)
- Workspace files (are SOUL.md and IDENTITY.md in place?)
- API key configuration (is an Anthropic key set?)
- Telegram token (is it configured and valid?)
- Network connectivity (can it reach the APIs?)

If everything is green, you're good to start the gateway. If something is red, the doctor tells you exactly what's wrong and how to fix it.

> **Pro tip:** Run `openclaw doctor` whenever something seems off. It's the fastest way to diagnose issues.

## Configuration: openclaw config

OpenClaw reads its configuration from `~/.openclaw/openclaw.json` (JSON5 format). You deployed this file via the GitHub Actions pipeline in Module 5. But you can also inspect and tweak individual settings with the CLI:

```bash
openclaw config get                    # Show all configuration
openclaw config get model              # Show a specific setting
openclaw config set model claude-sonnet # Change a setting
```

For quick tweaks, `openclaw config set` is convenient. For anything you want to persist across deploys, edit `config/openclaw.json` in your repo and push -- that's the whole point of config-as-code.

## SSH Tunneling: Viewing the Dashboard Safely

OpenClaw has a web dashboard that runs on port 18789. But our firewall only allows SSH (port 22) -- we can't just open `http://YOUR_VPS_IP:18789` in a browser. And we don't want to -- exposing the dashboard to the internet would be a security risk.

The solution is an **SSH tunnel**: a secure pipe from your local machine to the server, going through the encrypted SSH connection you already have.

```bash
ssh -L 18789:127.0.0.1:18789 openclaw
```

This says: "Forward my local port 18789 to port 18789 on the server, through the SSH connection." While this SSH session is open, you can visit `http://127.0.0.1:18789/` in your browser and see the OpenClaw dashboard.

The dashboard is useful for:
- Checking the gateway's current status
- Viewing recent conversations
- Monitoring performance
- Quick configuration changes

But you don't *need* the dashboard for daily operations. The CLI commands handle everything.

## Daily Operations: The Commands You'll Actually Use

Once your gateway is running, here's your daily toolkit. These are the commands you'll type most often:

```bash
# Check if the gateway is running
openclaw gateway status

# Restart the gateway (after config changes)
openclaw gateway restart

# Stop the gateway
openclaw gateway stop

# Start the gateway
openclaw gateway start

# Run diagnostics
openclaw doctor

# Check or change a config value
openclaw config get
openclaw config set key value

# Check support services
cd ~/openclaw
docker compose ps

# View support service logs
docker compose logs -f

# Check resource usage
free -h
df -h /
```

Notice what's NOT here: no `docker exec`. No `docker compose restart openclaw`. OpenClaw is native -- you talk to it directly. Docker is only for the support services (Cloudflare Tunnel, Uptime Kuma, kill switch).

## The Big Payoff Moment

Here's the scene:

1. Your VPS is running in a data center
2. OpenClaw's gateway is running natively on that VPS
3. You close your laptop lid
4. You pick up your phone
5. You send a Telegram message to your bot
6. A few seconds later, your bot responds

Your laptop is asleep. Your phone might even be on airplane mode after sending. But the message got to your VPS, OpenClaw processed it, called Claude, and sent the response through Telegram -- all without your laptop being involved.

*That's* what we've been building toward. A computer that works for you while you sleep.

## What Happens When Things Go Wrong

Things crash sometimes. It's not a matter of if, it's when. Here's what happens in the native setup:

1. **Gateway crashes** -- OpenClaw's gateway process exits unexpectedly. You'll need to restart it with `openclaw gateway start`. (In a later module, we'll set up systemd to auto-restart it.)

2. **Server reboots** -- The gateway doesn't automatically restart after a reboot (yet). After reboot, SSH in and run `openclaw gateway start`. The support services in Docker do auto-restart (they have `restart: unless-stopped`).

3. **Out of memory** -- Unlikely on the native setup (it uses <512MB), but the Linux OOM killer would terminate processes. Check with `free -h`.

4. **Bad configuration** -- Run `openclaw doctor` to diagnose. Fix the config, restart the gateway.

The common thread: `openclaw doctor` first, then `openclaw gateway restart`. Most issues are config-related, not infrastructure-related.

## Logs: Where to Look

OpenClaw logs to the console by default. To see what happened:

```bash
# Check the gateway's recent activity
openclaw gateway status

# For support services
cd ~/openclaw
docker compose logs -f          # All services
docker compose logs -f tunnel   # Just the Cloudflare tunnel
```

## What We Just Covered

- The OpenClaw gateway runs natively on port 18789 -- no Docker needed
- `openclaw doctor` validates your entire setup before you start
- `openclaw gateway start/stop/restart/status` manages the gateway directly
- SSH tunneling lets you view the dashboard without exposing ports
- Daily operations are a handful of native CLI commands + `docker compose ps` for support services
- The big payoff: close your laptop, your agent keeps working
- No docker exec, no container IDs, no compose files for OpenClaw -- it's native

Time to actually start the gateway. Head to the exercise.

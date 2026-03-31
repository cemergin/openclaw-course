# The Lethal Trifecta (And How Not to Die)

## A Story That Happens Every Day

Last year, a developer spun up a VPS to run a side project. They installed their app, opened port 3000 so they could access the web UI, put their API keys in a `.env` file, and went to bed feeling productive.

Here's what happened while they slept:

1. **Within 8 minutes**, an automated scanner (there are millions running 24/7) found their server's open port 3000
2. **Within 20 minutes**, a bot identified the service running behind that port and started probing for known vulnerabilities
3. **Within 2 hours**, someone accessed the app, found the environment variable dump in the default debug page, and pulled out the OpenAI API key
4. **By morning**, $847 in API charges. The key had been shared on a forum and dozens of people were running GPT-4 requests through it

The developer didn't find out for three days. They only noticed when their credit card got declined at a coffee shop.

This isn't a scare story. This is a *Tuesday*. The internet is constantly, automatically scanning every IP address on every common port. Your VPS got its first probe within seconds of being created -- check your SSH logs if you don't believe me.

The good news? Preventing this is straightforward. Not easy (you have to actually do it), but straightforward. Let's talk about what went wrong -- and then fix it.

---

## The Lethal Trifecta

Three things, when combined, guarantee you'll have a bad day:

```
   OPEN PORTS              EXPOSED SECRETS          NO MONITORING
   +-----------+           +-----------+            +-----------+
   | Port 22   |           | .env file |            | ???       |
   | Port 3000 |     +     | API keys  |      +     | No alerts |
   | Port 8080 |           | Tokens    |            | No logs   |
   +-----------+           +-----------+            +-----------+
        |                       |                        |
        v                       v                        v
   They find you          They get access           You don't know
```

Any ONE of these is a risk. All THREE together? That's not a question of *if* you get compromised. It's *when*.

Let's break down each leg, and then fix two of them today.

### Leg 1: Open Ports -- Every Door You Leave Open

Think of your server as a building. Every open port is a door that faces a busy street. Port 22 is the front door (SSH). Port 80 is the web entrance. Port 18789 might be OpenClaw's gateway.

The problem is that the "street" in this case is the entire internet, and there are automated robots walking down it 24/7, jiggling every doorknob they find.

Tools like **Shodan** and **nmap** exist specifically to scan IP addresses for open ports. Shodan indexes the *entire internet* and makes it searchable. Right now, you can go to shodan.io and search for every server running a specific service on a specific port. Attackers don't even need to scan -- someone's already done it for them.

When you run a service that listens on a port, you've opened a door. Anyone on the internet who knows your IP (and your IP is easy to find -- it's a static IP, remember?) can connect to that port.

### Leg 2: Exposed Secrets -- The Keys Under the Mat

API keys, tokens, passwords -- these are the keys to your digital life. Your Claude API key controls your billing. Your GitHub token controls who can push code to your repos.

Where do people put these? In `.env` files. In environment variables. In config files. Sometimes committed to git repos. We'll dig deep into why this is dangerous in a minute.

### Leg 3: No Monitoring -- The Silent Killer

Imagine your smoke detector has dead batteries. A fire starts in the kitchen. You're asleep. By the time you smell smoke, it's too late.

No monitoring is the dead battery. Your server gets compromised, your bot starts acting weird, your API charges spike -- and you have no idea. You find out days later when the damage is done.

> **The bigger picture:** Module 9 is entirely about monitoring. We'll set up Uptime Kuma, health checks, and notifications. For now, know *why* it matters so you're motivated when we get there.

---

## The Security Mental Model

Before we start fixing things, let's build a framework for thinking about security.

### Attack Surface: Everything They Can Touch

Your **attack surface** is everything a potential attacker can probe, poke, or exploit. Every open port. Every exposed service. Every file with loose permissions. Every API key sitting in plaintext.

The goal is to make your attack surface as small as possible:

| More surface (bad)                | Less surface (good)                    |
|-----------------------------------|----------------------------------------|
| 5 ports open                      | Only SSH open (or zero with tunnel)    |
| Running as root                   | Dedicated non-root user                |
| API keys in environment variables | Secrets in dedicated files             |
| Default software installed        | Only what you need                     |

Every decision you make should shrink the surface. "Do I need this port open?" No? Close it. "Does this token need write access?" No? Make it read-only.

### Defense in Depth: Layers, Not Walls

No single security measure is enough. Think of it like a medieval castle:

```
Layer 1: Moat (firewall) ............... Blocks most attackers before they try
Layer 2: Walls (Cloudflare Tunnel) ..... No ports to attack, invisible to scanners
Layer 3: Vault (secrets management) .... Keys locked away, not lying around
Layer 4: Watchtower (monitoring) ....... You know immediately if something's wrong
Layer 5: Emergency bell (kill switch) .. Shut it all down in seconds from your phone
```

If the moat gets crossed, the walls stop them. If the walls are breached, the vault protects the valuables. Each layer is independent. An attacker has to beat *all* of them, not just one.

### Security Theater vs Real Security

Let's be honest about what *doesn't* work:

- **Changing SSH from port 22 to port 2222:** Port scanners check all ports. You've inconvenienced yourself without stopping anyone.
- **Using an obscure URL as your "secret" endpoint:** If the URL is in your browser history, server logs, or Cloudflare dashboard, it's not secret.
- **"I'm too small to be a target":** Automated scanners don't care how small you are. They scan *every* IP address. Your VPS isn't targeted -- it's swept up with everything else.

Real security is boring. Firewalls, least privilege, encryption, monitoring, and keeping things updated. Not clever tricks.

---

## Your First Real Defense: UFW Firewall

UFW (Uncomplicated Firewall) is Ubuntu's built-in firewall. It's called "uncomplicated" because the syntax is human-readable, unlike its underlying tool `iptables` (which looks like someone encrypted their own configuration files).

The philosophy is simple:

1. **Block everything incoming** by default
2. **Allow everything outgoing** by default (your server needs to call APIs, maintain tunnels, etc.)
3. **Poke specific holes** only for what you need (SSH)

```bash
# Step 1: Default deny all incoming
sudo ufw default deny incoming

# Step 2: Default allow all outgoing
sudo ufw default allow outgoing

# Step 3: Allow SSH (port 22)
sudo ufw allow 22

# Step 4: Enable the firewall
sudo ufw enable

# Step 5: Verify
sudo ufw status verbose
```

After this, your server ignores all incoming traffic except SSH.

**For native OpenClaw, this just works.** OpenClaw runs as a regular process on the VPS. When UFW says "deny incoming on port 18789," OpenClaw's gateway port is blocked from the outside. Normal, expected behavior. This is how firewalls are supposed to work.

---

## CRITICAL: Docker Bypasses UFW (But Only for Docker Containers)

This is the single most important security fact in this entire course. Read it twice.

**Docker modifies iptables directly, completely bypassing UFW.** If you expose a port in Docker (with `-p 3001:3001` or `ports: - "3001:3001"` in docker-compose), that port is open to the entire internet -- even if UFW says "deny all incoming."

Let me say that again: **UFW says no, Docker says yes, Docker wins.**

This matters because our support services -- cloudflared, Uptime Kuma, the kill switch -- run in Docker. If you expose their ports without care, they're accessible to the entire internet regardless of your firewall.

But here's the good news: **OpenClaw runs natively, not in Docker.** So UFW works perfectly for OpenClaw's ports. The firewall does its job. The bypass problem only applies to the Docker support containers.

### The Fix: Always Bind Docker Containers to 127.0.0.1

The solution for Docker containers is simple but absolutely critical. Instead of exposing ports to the world, bind them to localhost only:

```yaml
# BAD -- exposed to the entire internet, UFW cannot save you
ports:
  - "3001:3001"

# GOOD -- only accessible from the server itself
ports:
  - "127.0.0.1:3001:3001"
```

The `127.0.0.1:` prefix means "only listen on the loopback interface." The port is accessible from inside the server but invisible from outside. Combined with Cloudflare Tunnel (Module 8), which routes traffic through an outbound connection, your services are reachable without any open ports.

```
Without 127.0.0.1 (Docker container):
Internet --> Docker port 3001 --> Uptime Kuma   (UFW bypassed!)

With 127.0.0.1 (Docker container):
Internet --> [BLOCKED]                           (Docker only listens locally)
Cloudflare Tunnel --> localhost:3001 --> Uptime Kuma (outbound connection, no open ports)

Native OpenClaw:
Internet --> [BLOCKED by UFW]                    (UFW works normally)
Cloudflare Tunnel --> localhost:18789 --> OpenClaw gateway (outbound connection)
```

**This is not optional for Docker containers.** Every single port binding in every `docker-compose.yml` you write for the rest of this course -- and for the rest of your life -- should use the `127.0.0.1:` prefix unless you have a very specific reason not to.

> **Pro tip:** The Docker/UFW bypass happens because Docker injects rules into iptables at a higher priority than UFW. There are workarounds involving Docker daemon configuration, but the `127.0.0.1:` approach is simpler, more portable, and works everywhere. It's the right fix.

---

## Automatic Security Updates

Your server's operating system has vulnerabilities. New ones are discovered regularly. Ubuntu releases patches, but they don't install themselves unless you tell them to.

```bash
sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure -plow unattended-upgrades
```

This configures Ubuntu to automatically download and install security patches. Select "Yes" when prompted.

This is a "set it and forget it" defense. The alternative is remembering to SSH in and run `sudo apt update && sudo apt upgrade` every few days. You won't. Nobody does.

---

## Part 2: Why .env Files Are Dangerous

Now let's tackle the second leg of the trifecta: exposed secrets.

".env files are the standard way to configure apps" -- you'll read this in approximately ten thousand tutorials. Those tutorials aren't *wrong*, exactly. Environment variables work. They're convenient. Every framework supports them.

They're also a security liability. Here are five ways they leak.

### Leak Vector 1: docker inspect

Run this on any container that uses environment variables:

```bash
docker inspect <container_name> | grep -A 50 '"Env"'
```

Every single environment variable -- including your API keys -- is right there in plain text. Anyone who can run `docker` commands (which is anyone in the `docker` group) can see every secret in every container.

### Leak Vector 2: The /proc Filesystem

Linux exposes every process's environment in `/proc`:

```bash
cat /proc/<pid>/environ | tr '\0' '\n'
```

Root can read this for any process. If an attacker escalates to root, your environment variables are sitting right there in the kernel's process table. This applies to *both* Docker containers and native processes like OpenClaw.

### Leak Vector 3: Child Processes

Environment variables are *inherited* by child processes. If your app spawns a subprocess -- a script, a health check, a plugin -- that subprocess gets a copy of every environment variable, including your secrets. If that subprocess logs its environment (some do by default in debug mode), your secrets are in the logs.

### Leak Vector 4: Logs and Error Reports

Many frameworks dump environment variables in crash reports or debug output. Docker's own logging can capture them. If you've ever run `docker compose up` (without `-d`) and scrolled through the startup output, you may have noticed config values scrolling by.

### Leak Vector 5: Shell History

If you ever set an environment variable manually:

```bash
export ANTHROPIC_API_KEY=sk-ant-api03-xxxx
```

Congratulations, it's now in your `.bash_history` file. Forever.

---

## The Fix: Two Approaches for a Hybrid Stack

Because our stack is hybrid -- OpenClaw runs natively, support services run in Docker -- we need two different secrets management approaches. Same principle (file-based secrets), different mechanisms.

### Approach 1: OpenClaw SecretRef Pattern (for native OpenClaw)

OpenClaw has a built-in mechanism for file-based secrets called **SecretRef**. Instead of passing secrets as environment variables, you tell OpenClaw to read each secret from a file on disk.

In your `openclaw.json` configuration, secrets look like this:

```json
{
  "anthropic": {
    "api_key": {
      "source": "file",
      "id": "/home/ubuntu/openclaw-deploy/secrets/anthropic_api_key"
    }
  },
  "github": {
    "token": {
      "source": "file",
      "id": "/home/ubuntu/openclaw-deploy/secrets/github_token"
    }
  }
}
```

Each secret reference has two fields:

- **`source`**: Always `"file"` -- tells OpenClaw to read from the filesystem
- **`id`**: The absolute path to the secret file on disk

When OpenClaw starts, it reads each secret from the specified file. The secret never exists as an environment variable. It's not in `/proc/<pid>/environ`. It's not in shell history. It's read once from a locked-down file and used internally.

This is the cleanest approach: the application is designed for it, and the secrets stay out of every leak vector we discussed.

### Approach 2: Docker Compose Secrets (for support services)

For Docker containers like cloudflared and Uptime Kuma, we use Docker Compose's built-in secrets mechanism -- the same approach from the previous version of this course, but now only for the support services.

You declare secrets at two levels in `docker-compose.yml` -- once at the top level (where Docker finds the files) and once per service (which services get access):

```yaml
services:
  cloudflared:
    secrets:
      - cloudflare_tunnel_token

secrets:
  cloudflare_tunnel_token:
    file: ./secrets/cloudflare_tunnel_token
```

Docker mounts each secret as a read-only file at `/run/secrets/<name>` inside the container. The secret does NOT show up in `docker inspect`.

Alternatively, for simpler cases, you can use an `env_file` pointing to a `.gitignored` `.env.secrets` file:

```yaml
services:
  uptime-kuma:
    env_file:
      - .env.secrets
```

The `env_file` approach is less secure than proper Docker secrets (the values still appear as environment variables inside the container), but it's simpler for services that don't support reading from `/run/secrets/`. The key thing: `.env.secrets` must be in `.gitignore` and never committed.

### Summary: Which Approach Where

| Component | Runs As | Secrets Method | How |
|---|---|---|---|
| OpenClaw | Native process | SecretRef in `openclaw.json` | `{ "source": "file", "id": "/path/to/secret" }` |
| cloudflared | Docker container | Docker Compose secrets | Mounted at `/run/secrets/` |
| Uptime Kuma | Docker container | env_file or Docker secrets | `.env.secrets` (gitignored) |
| Kill switch | Docker container | Environment vars in compose | Inline (it's a shell script) |

---

## Setting Up the Secrets Directory

Both approaches share the same secrets directory on the host:

**Step 1: Create the directory**

```bash
mkdir -p ~/openclaw-deploy/secrets
chmod 700 ~/openclaw-deploy/secrets
```

`chmod 700` means: only the owner can read, write, or enter this directory. Everyone else gets nothing.

**Step 2: One file per secret**

Each secret gets its own file:

```bash
echo -n "sk-ant-api03-your-actual-key" > ~/openclaw-deploy/secrets/anthropic_api_key
echo -n "your-github-token" > ~/openclaw-deploy/secrets/github_token
```

That `-n` flag on `echo` is important -- it prevents adding a trailing newline character to the file. A newline at the end of your API key will cause authentication failures that are incredibly annoying to debug.

**Step 3: Lock down file permissions**

```bash
chmod 600 ~/openclaw-deploy/secrets/*
```

`chmod 600` means: only the file owner can read or write the file. No one else can even see its contents.

---

## What Stays in .env? (Non-Secret Config)

Not everything is a secret. Some configuration values are just... configuration. Service URLs, log levels, timezones -- these aren't sensitive.

Keep non-secret config in a regular `.env` file:

```bash
# .env -- non-secret configuration
LOG_LEVEL=info
TIMEZONE=UTC
```

The rule of thumb: **if someone seeing this value could cost you money, impersonate you, or access your accounts, it's a secret.** Everything else is config.

| Value | Secret? | Where it goes |
|---|---|---|
| API keys (Claude, OpenAI) | Yes | `secrets/` file + SecretRef in openclaw.json |
| Access tokens (GitHub) | Yes | `secrets/` file + SecretRef in openclaw.json |
| Cloudflare tunnel token | Yes | `secrets/` file + Docker Compose secrets |
| Internal service URLs | No | `.env` or `openclaw.json` config |
| Log level | No | `.env` or `openclaw.json` config |
| Timezone | No | `.env` |

---

## The Security Checklist

Here's the checklist you'll use for the rest of this course. Some items you can check off today. Others come in later modules.

**Firewall and Network (this module + Module 8)**
- [ ] UFW enabled, default deny incoming
- [ ] SSH allowed (port 22)
- [ ] All Docker support container port bindings use `127.0.0.1:` prefix
- [ ] OpenClaw gateway port (18789) blocked from outside by UFW (native = firewall works)
- [ ] Cloudflare Tunnel running (Module 8)
- [ ] No unnecessary ports open

**Secrets -- OpenClaw (this module)**
- [ ] Secrets directory created with `chmod 700`
- [ ] Each secret in its own file with `chmod 600`
- [ ] `openclaw.json` updated with SecretRef pattern for all secrets
- [ ] No secrets in environment variables or `.env` file
- [ ] No secrets committed to git

**Secrets -- Docker Support Services (this module)**
- [ ] Docker Compose secrets configured for cloudflared token
- [ ] Support service secrets stored in files with `chmod 600`
- [ ] `docker inspect` does NOT reveal secrets for any container

**System Hardening**
- [ ] Running as dedicated `openclaw` user, not root
- [ ] Automatic OS security updates enabled
- [ ] SSH key authentication configured

**Monitoring and Response (Module 9)**
- [ ] Health check monitoring configured
- [ ] Alert notifications set up
- [ ] Kill switch available

You'll find a printable version of this in `starter/security-checklist.md`. By the time you finish the course, every box should be checked.

---

## What We Covered

This was a dense one. Here's the core of it:

1. **The lethal trifecta** -- open ports, exposed secrets, and no monitoring. Together, they guarantee problems.
2. **UFW firewall** -- deny everything incoming, allow only SSH. Works normally for native OpenClaw.
3. **Docker bypasses UFW** -- this is the critical gotcha for support containers. Always use `127.0.0.1:` in port bindings for Docker services.
4. **Auto-updates** -- keep the OS patched without thinking about it.
5. **Environment variables leak** through docker inspect, /proc, child processes, logs, and shell history.
6. **OpenClaw SecretRef pattern** reads secrets from files via `openclaw.json` config -- no environment variables needed.
7. **Docker Compose secrets** mount as files at `/run/secrets/`, invisible to docker inspect, used for support services.
8. **File permissions** (600 for files, 700 for directories) are your first line of defense for secrets at rest.

The security checklist isn't a one-time thing. Every time you add a new service or change a configuration, come back to it. "Did I just increase my attack surface? Did I give more access than needed? Are my Docker port bindings using 127.0.0.1?"

That habit -- asking the question -- is worth more than any individual tool.

Now let's go lock down your server. Head to the [exercise](exercise.md).

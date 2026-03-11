# Lesson: Secrets Management -- Not Just a .env File

## What Does an Attacker See?

Let's start with a thought experiment that should make you uncomfortable.

Someone gets shell access to your VPS. Maybe they exploited a vulnerability in an exposed service. Maybe they found an SSH key you accidentally committed to GitHub (it happens -- a lot). Maybe a rogue npm package phoned home. However they got in, they're sitting at a terminal on your server.

How long until they have every API key you own?

If you're using `.env` files, the answer is about four seconds:

```bash
$ cat .env
ANTHROPIC_API_KEY=sk-ant-api03-xxxxxxxxxxxxxxxxxxxx
WHATSAPP_ACCESS_TOKEN=EAAxxxxxxxxxxxxxxxxxxxxxxxx
WHATSAPP_APP_SECRET=abc123def456
GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx
```

Game over. They have your Claude key (your money), your WhatsApp token (your identity), your GitHub token (your code). Four seconds. One command.

But here's the thing that surprises most people: **even without the `.env` file itself, environment variables are almost as easy to steal.**

---

## The Problem with Environment Variables

".env files are the standard way to configure Docker apps" -- you'll read this in approximately ten thousand tutorials. And those tutorials aren't *wrong*, exactly. Environment variables work. They're convenient. Every framework supports them.

They're also a security liability, and here's why.

### Leak Vector 1: docker inspect

Run this on any container that uses environment variables:

```bash
docker inspect <container_name> | grep -A 50 '"Env"'
```

Every single environment variable -- including your API keys -- is right there in plain text. Anyone who can run `docker` commands (which is anyone in the `docker` group, which probably includes your `openclaw` user) can see every secret in every container.

### Leak Vector 2: The /proc Filesystem

Linux exposes every process's environment in `/proc`:

```bash
cat /proc/<pid>/environ | tr '\0' '\n'
```

Root can read this for any process. And remember, if an attacker has escalated to root, your environment variables are sitting right there in the kernel's process table.

### Leak Vector 3: Child Processes

Environment variables are *inherited* by child processes. If your app spawns a subprocess -- a script, a health check, a plugin -- that subprocess gets a copy of every environment variable, including your secrets. If that subprocess logs its environment (some do by default in debug mode), your secrets are in the logs.

### Leak Vector 4: Logs and Error Reports

Many frameworks dump environment variables in crash reports or debug output. Docker's own logging can capture them. If you've ever run `docker compose up` (without `-d`) and scrolled through the startup output, you may have noticed config values scrolling by. Some of those might be secrets.

### Leak Vector 5: Shell History

If you ever set an environment variable manually:

```bash
export ANTHROPIC_API_KEY=sk-ant-api03-xxxx
```

Congratulations, it's now in your `.bash_history` file. Forever. (Well, until you remember to delete it. Which you won't.)

> **The Bigger Picture:** This isn't a Docker-specific problem. Environment variables leaking is a known issue across the entire software industry. AWS, Google Cloud, and Azure all offer dedicated secrets management services (AWS Secrets Manager, Google Secret Manager, Azure Key Vault) specifically because environment variables aren't good enough for production. What we're about to do is the self-hosted equivalent of those services.

---

## The Fix: Docker File-Based Secrets

Here's the approach we're going to use. It's simple, it's effective, and it's built into Docker Compose:

**Instead of passing secrets as environment variables, we store each secret in its own file and mount those files into the container.**

The secrets end up at `/run/secrets/<name>` inside the container -- a path that:

- Does NOT show up in `docker inspect`
- Does NOT appear in `/proc/<pid>/environ`
- Does NOT get inherited by child processes
- Does NOT get logged by Docker

Let's build it.

### Step 1: Create a Secrets Directory

```bash
mkdir -p ~/openclaw/secrets
chmod 700 ~/openclaw/secrets
```

`chmod 700` means: only the owner can read, write, or enter this directory. Everyone else gets nothing.

### Step 2: One File Per Secret

Each secret gets its own file. The filename becomes the secret's name:

```bash
echo -n "sk-ant-api03-your-actual-key" > ~/openclaw/secrets/anthropic_api_key
echo -n "EAAyour-actual-token" > ~/openclaw/secrets/whatsapp_access_token
echo -n "your-actual-app-secret" > ~/openclaw/secrets/whatsapp_app_secret
echo -n "your-webhook-verify-token" > ~/openclaw/secrets/whatsapp_verify_token
```

That `-n` flag on `echo` is important -- it prevents adding a trailing newline character to the file. A newline at the end of your API key will cause authentication failures that are incredibly annoying to debug. Ask me how I know.

### Step 3: Lock Down File Permissions

```bash
chmod 600 ~/openclaw/secrets/*
```

`chmod 600` means: only the file owner can read or write the file. No one else can even see its contents.

> **Pro tip:** Want to verify the permissions are correct? Run `ls -la ~/openclaw/secrets/`. You should see `-rw-------` for each file (read-write for owner, nothing for anyone else) and `drwx------` for the directory itself.

### Step 4: Wire It Into Docker Compose

In your `docker-compose.yml`, you declare secrets at two levels -- once at the top level (where Docker finds them) and once per service (which services get access):

```yaml
services:
  openclaw:
    image: openclaw/openclaw:latest
    secrets:
      - anthropic_api_key
      - whatsapp_access_token
      - whatsapp_app_secret
      - whatsapp_verify_token

secrets:
  anthropic_api_key:
    file: ./secrets/anthropic_api_key
  whatsapp_access_token:
    file: ./secrets/whatsapp_access_token
  whatsapp_app_secret:
    file: ./secrets/whatsapp_app_secret
  whatsapp_verify_token:
    file: ./secrets/whatsapp_verify_token
```

When the container starts, Docker mounts each secret as a read-only file at `/run/secrets/<name>`. Inside the container:

```bash
cat /run/secrets/anthropic_api_key
# outputs: sk-ant-api03-your-actual-key
```

The secret exists inside the container, but *only* as a file at that specific path. It's not in the environment. It's not in Docker's metadata. It's not inspectable from outside.

---

## The Entrypoint Wrapper Pattern

There's one catch: some applications (including OpenClaw, depending on your version) expect secrets as environment variables, not files. They look for `ANTHROPIC_API_KEY` in the environment, not in `/run/secrets/`.

The solution is an **entrypoint wrapper** -- a tiny script that runs before your app starts, reads the secret files, exports them as environment variables, and then launches the app:

```bash
#!/bin/sh
# entrypoint-wrapper.sh
# Converts Docker secrets (files) to environment variables at startup.
# This way, secrets never exist in Docker's metadata or inspect output --
# they only appear in the process environment at runtime.

for secret_file in /run/secrets/*; do
  if [ -f "$secret_file" ]; then
    var_name=$(basename "$secret_file" | tr '[:lower:]' '[:upper:]')
    export "$var_name"="$(cat "$secret_file")"
  fi
done

# Hand off to the real entrypoint
exec "$@"
```

"Wait," you're thinking. "Doesn't this just put them back into environment variables? Didn't we just say that's bad?"

Good question. The difference is *where* the environment variables exist:

- **With .env:** The secrets are in Docker's metadata, visible via `docker inspect`, stored in Docker's internal config, and passed through Docker's API. They exist before the container even starts.
- **With the wrapper:** The secrets only exist in the running process's environment *after* the entrypoint runs. They're not in Docker's metadata. `docker inspect` shows nothing. The secrets live only in the process that needs them.

It's not perfect (they're still in `/proc/<pid>/environ` for root), but it eliminates the easiest and most common attack vectors.

> **Pro tip:** The `exec "$@"` at the end is crucial. It replaces the wrapper script's process with the actual application, so there's no extra shell process hanging around. This matters for signal handling -- when Docker sends SIGTERM to stop the container, it reaches your app directly.

---

## What Stays in .env? (Non-Secret Config)

Not everything is a secret. Some configuration values are just... configuration. Phone number IDs, allowed numbers, service URLs -- these aren't sensitive. An attacker who knows your SearXNG runs on port 8080 can't do anything with that information.

Keep non-secret config in a regular `.env` file:

```bash
# .env -- non-secret configuration
ALLOWED_NUMBERS=+905551234567,+905559876543
WHATSAPP_PHONE_NUMBER_ID=123456789
SEARXNG_BASE_URL=http://searxng:8080
LOG_LEVEL=info
TIMEZONE=Europe/Istanbul
```

The rule of thumb: **if someone seeing this value could cost you money, impersonate you, or access your accounts, it's a secret.** Everything else is config.

Here's a quick cheat sheet:

| Value | Secret? | Where it goes |
|---|---|---|
| API keys (Claude, OpenAI) | Yes | `secrets/` file |
| Access tokens (WhatsApp, GitHub) | Yes | `secrets/` file |
| App secrets (webhook verification) | Yes | `secrets/` file |
| Phone number allowlist | No | `.env` |
| Phone number IDs | No | `.env` |
| Internal service URLs | No | `.env` |
| Log level | No | `.env` |
| Timezone | No | `.env` |

---

## Option B: SOPS + age (Encrypted at Rest)

Docker file-based secrets solve the runtime problem -- secrets aren't visible via Docker's API. But the secret files themselves still sit on disk in plain text. If someone gets into your `secrets/` directory, they can read them.

For most personal deployments, file permissions (`chmod 600`) are sufficient. But if you want an extra layer -- especially if you want to commit your secrets to a git repo (useful for backup and version control) -- you can encrypt them at rest with **SOPS + age**.

Here's the concept:

1. **age** generates a keypair (public key for encryption, private key for decryption)
2. **SOPS** uses age to encrypt YAML/JSON files, but smartly -- it encrypts only the *values*, not the keys, so you can still see what secrets exist without revealing their contents
3. You commit the encrypted file to git. Safe. Even if someone clones your repo, they can't read the values.
4. At deploy time on your VPS, you decrypt the file and write the individual secret files.

```bash
# Generate a key pair (do this once)
age-keygen -o age-key.txt
# Public key: age1xxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Encrypt a secrets file
sops --encrypt --age age1xxxxxxxxxxxxxxxxxxxxxxxxxxxx secrets.yaml > secrets.enc.yaml

# The encrypted file is safe to commit to git
git add secrets.enc.yaml

# On your VPS, decrypt it
sops --decrypt secrets.enc.yaml > secrets.yaml
```

This is genuinely useful if you manage multiple servers or want version-controlled secrets. But for a single VPS running OpenClaw, it's extra complexity that may not be worth it. We include it here so you know the option exists.

> **Pro tip:** If you go the SOPS route, your `age-key.txt` private key becomes the ONE secret you need to protect above all others. Guard it like you'd guard your SSH private key. Never commit it. Never email it. Consider storing it in a password manager.

---

## Option C: Password Manager CLI

If you already use Bitwarden or 1Password, their CLI tools can pull secrets directly at deploy time:

```bash
# Bitwarden example
bw login
bw get notes "openclaw/anthropic_api_key" > secrets/anthropic_api_key
bw get notes "openclaw/whatsapp_access_token" > secrets/whatsapp_access_token

# 1Password example
op read "op://OpenClaw/Anthropic/api_key" > secrets/anthropic_api_key
```

The appeal: your secrets live in a tool you already trust and use, with its own encryption, access controls, and audit logging. The downside: you need an active session to deploy, which makes automated deployments harder.

This is a great option if you already have a password manager workflow and don't want to learn SOPS.

---

## Which Approach Should You Pick?

| Approach | Complexity | Security | Best For |
|---|---|---|---|
| **Docker file-based secrets** | Low | Good | Most people. This is what we recommend and what the rest of the course assumes. |
| **SOPS + age** | Medium | Better (encrypted at rest) | People who want secrets in version control or manage multiple servers. |
| **Password manager CLI** | Medium | Good+ (leverages existing tool) | People already deep in 1Password or Bitwarden. |
| **.env file** | Trivial | Poor | Speed Run only. Not for production. |

For this course, we're going with Docker file-based secrets. It's the best balance of security and simplicity, and it integrates cleanly with the Docker Compose setup we'll build in Module 9.

---

## What You Just Learned

Let's take stock:

- **Environment variables leak** through docker inspect, /proc, child processes, logs, and shell history -- five separate vectors
- **Docker file-based secrets** mount as files at `/run/secrets/`, invisible to docker inspect and environment dumps
- **The entrypoint wrapper** bridges the gap when apps expect env vars, without exposing secrets in Docker's metadata
- **Non-secret config** stays in `.env` -- the test is "could this value cost me money or access?"
- **SOPS + age** encrypts secrets at rest (great for git, optional for single servers)
- **Password manager CLIs** let you pull secrets from tools you already trust
- **File permissions (600 for files, 700 for directories)** are your first line of defense

You've just closed the "exposed secrets" leg of the lethal trifecta. One down, two to go.

Now let's implement it.

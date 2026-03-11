# Exercise: Implementing Docker File-Based Secrets

## What We're Doing

We're going to create a proper secrets directory, write secret files with locked-down permissions, wire them into a Docker Compose file, verify they're invisible to `docker inspect`, and build the entrypoint wrapper that bridges secrets to environment variables.

## Prerequisites

- SSH access to your VPS as the `openclaw` user
- Docker and Docker Compose installed (Module 4)
- A terminal open and connected to your server
- The starter files from this module (`docker-compose-secrets.yml` and `entrypoint-wrapper.sh`)

---

## Step 1: Create the Secrets Directory

SSH into your VPS and set up the directory structure:

```bash
cd ~/openclaw
mkdir -p secrets
chmod 700 secrets
```

Verify the permissions:

```bash
ls -la | grep secrets
```

You should see `drwx------` -- that's read/write/execute for the owner only. Nobody else can even `ls` into this directory.

## Step 2: Create Your Secret Files

We're going to use placeholder values for now. When you have real API keys (Module 8 for WhatsApp, Module 1 for Claude), you'll replace these.

```bash
echo -n "sk-ant-api03-placeholder-key" > secrets/anthropic_api_key
echo -n "placeholder-whatsapp-token" > secrets/whatsapp_access_token
echo -n "placeholder-app-secret" > secrets/whatsapp_app_secret
echo -n "placeholder-verify-token" > secrets/whatsapp_verify_token
```

**Before continuing, predict:** what will `cat secrets/anthropic_api_key` show? Will there be a trailing newline? (Hint: remember the `-n` flag.)

Verify -- check one of the files:

```bash
cat secrets/anthropic_api_key
echo ""
```

The `echo ""` after `cat` just adds a newline so your terminal prompt doesn't land on the same line as the secret. The file itself has no trailing newline.

## Step 3: Lock Down File Permissions

```bash
chmod 600 secrets/*
```

Verify:

```bash
ls -la secrets/
```

Every file should show `-rw-------`. Only the owner can read or write. Nobody else can even see the contents.

> **Pro tip:** A common mistake is creating the files first and forgetting to set permissions. Make it a habit: `chmod 600` immediately after creating any secret file. Better yet, set the directory permissions first (`chmod 700 secrets/`) so even the briefly-unprotected files are inside a locked directory.

## Step 4: Create the Non-Secret .env File

Some configuration isn't sensitive. Create the `.env` file for those values:

```bash
cat > ~/openclaw/.env << 'EOF'
# Non-secret configuration
# These values are not sensitive -- they don't grant access to anything.
ALLOWED_NUMBERS=+905551234567
WHATSAPP_PHONE_NUMBER_ID=123456789
SEARXNG_BASE_URL=http://searxng:8080
LOG_LEVEL=info
TIMEZONE=UTC
EOF
```

Notice: no API keys, no tokens, no secrets. Just configuration.

## Step 5: Create the Entrypoint Wrapper

Copy the starter file to your server, or create it directly:

```bash
cat > ~/openclaw/entrypoint-wrapper.sh << 'SCRIPT'
#!/bin/sh
# entrypoint-wrapper.sh
# Converts Docker secrets (files in /run/secrets/) to environment variables.
# Secrets stay out of Docker's metadata -- they only exist in the running process.

for secret_file in /run/secrets/*; do
  if [ -f "$secret_file" ]; then
    var_name=$(basename "$secret_file" | tr '[:lower:]' '[:upper:]')
    export "$var_name"="$(cat "$secret_file")"
  fi
done

# Hand off to the real command
exec "$@"
SCRIPT

chmod +x ~/openclaw/entrypoint-wrapper.sh
```

Verify it's executable:

```bash
ls -la entrypoint-wrapper.sh
```

You should see `-rwxr-xr-x` (or similar with execute bits set).

## Step 6: Create the Docker Compose File with Secrets

Now for the main event. Create a test compose file that uses secrets:

```bash
cat > ~/openclaw/docker-compose-secrets.yml << 'EOF'
version: "3.8"

services:
  secret-test:
    image: alpine:latest
    entrypoint: ["/entrypoint-wrapper.sh"]
    command: ["sh", "-c", "echo 'Secrets loaded. Sleeping...' && sleep 3600"]
    volumes:
      - ./entrypoint-wrapper.sh:/entrypoint-wrapper.sh:ro
    secrets:
      - anthropic_api_key
      - whatsapp_access_token
      - whatsapp_app_secret
      - whatsapp_verify_token
    env_file:
      - .env

secrets:
  anthropic_api_key:
    file: ./secrets/anthropic_api_key
  whatsapp_access_token:
    file: ./secrets/whatsapp_access_token
  whatsapp_app_secret:
    file: ./secrets/whatsapp_app_secret
  whatsapp_verify_token:
    file: ./secrets/whatsapp_verify_token
EOF
```

## Step 7: Start the Test Container

```bash
docker compose -f docker-compose-secrets.yml up -d
```

Verify it's running:

```bash
docker compose -f docker-compose-secrets.yml ps
```

You should see the `secret-test` container with status "Up."

## Step 8: Verify Secrets Are Mounted Inside the Container

Let's peek inside:

```bash
docker compose -f docker-compose-secrets.yml exec secret-test ls -la /run/secrets/
```

You should see all four secret files. Now read one:

```bash
docker compose -f docker-compose-secrets.yml exec secret-test cat /run/secrets/anthropic_api_key
```

It's there. The container can read its secrets. Good.

## Step 9: Verify the Entrypoint Wrapper Works

Check that the wrapper script converted secrets to environment variables:

```bash
docker compose -f docker-compose-secrets.yml exec secret-test sh -c 'echo $ANTHROPIC_API_KEY'
```

You should see `sk-ant-api03-placeholder-key`. The wrapper read the file and exported it.

## Step 10: The Big Test -- Prove Secrets Are Hidden from Docker Inspect

This is the moment of truth. Run:

```bash
docker compose -f docker-compose-secrets.yml exec secret-test env | sort
```

**Before you look at the output, predict:** will you see `ANTHROPIC_API_KEY` in the environment listing from *inside* the container?

Yes, you will -- because the entrypoint wrapper exported it into the running process.

Now try from *outside* the container:

```bash
docker inspect $(docker compose -f docker-compose-secrets.yml ps -q secret-test) | grep -A 50 '"Env"'
```

**Predict:** will `ANTHROPIC_API_KEY` appear in the docker inspect output?

No. You'll see the non-secret `.env` values (ALLOWED_NUMBERS, SEARXNG_BASE_URL, etc.) but the secrets are nowhere to be found. That's the whole point.

> **Pro tip:** Compare this to what happens with a regular `.env` file containing secrets. The difference is stark and should make you slightly uncomfortable about every `.env`-based deployment you've ever done.

## Step 11: Clean Up

```bash
docker compose -f docker-compose-secrets.yml down
```

---

## What Just Happened?

Let's trace what you just built:

1. **Secret files** live in `~/openclaw/secrets/` with `600` permissions (owner-only read/write)
2. **The secrets directory** has `700` permissions (owner-only access)
3. **Docker Compose** mounts each secret file into the container at `/run/secrets/<name>`
4. **The entrypoint wrapper** converts those files to environment variables at process startup
5. **docker inspect** shows NOTHING about the secrets -- they're not in Docker's metadata
6. **Non-secret config** stays in `.env` where it belongs

The secrets exist only where they're needed: inside the running process, readable only by the process that needs them.

---

## Try This (Optional Experiments)

**Experiment 1: What happens without `-n`?**

Create a test secret WITH a trailing newline and see what breaks:

```bash
echo "test-key-with-newline" > /tmp/test_key
xxd /tmp/test_key | tail -1
```

See that `0a` at the end? That's a newline character. Now imagine that getting appended to your API key when the app reads it. Authentication fails and you spend an hour debugging "invalid API key" errors.

**Experiment 2: Try to read secrets from another user**

If you have a second user on the system, try switching to them and reading the secrets:

```bash
sudo su - ubuntu
cat /home/openclaw/openclaw/secrets/anthropic_api_key
```

Permission denied. That's `chmod 600` doing its job.

**Experiment 3: Count your attack surface**

List everywhere your old `.env` secrets would have been visible:

```bash
# These would ALL show your secrets with a .env approach:
# 1. cat .env
# 2. docker inspect <container>
# 3. docker compose exec <service> env
# 4. /proc/<pid>/environ (as root)
# 5. Shell history if you ever export-ed them

# With Docker secrets:
# 1. cat secrets/<file> (requires file owner permissions)
# 2. /proc/<pid>/environ (requires root)
# That's it. Three attack vectors eliminated.
```

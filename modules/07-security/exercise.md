# Exercise: Lock Down Your Server + Implement Secrets Management

## What We're Doing

We're going to configure a firewall, enable automatic security updates, set up file-based secrets for both native OpenClaw (SecretRef) and Docker support services (Compose secrets), and verify the whole thing works. By the end of this exercise, your server will be significantly harder to attack than it was an hour ago.

## Prerequisites

- SSH access to your VPS as the `openclaw` user (from Module 3)
- OpenClaw installed and running natively on the VPS (from Module 5)
- Docker and Docker Compose installed for support services (from Module 4)
- Your bot currently running via GitHub Actions deploy (from Module 6)
- About 45 minutes

---

## Part 1: Check Your Current State

Before we fix things, let's see how exposed you are right now.

**1.** SSH into your VPS:

```bash
ssh openclaw@YOUR_VPS_IP
```

**2.** Check what ports are currently listening:

```bash
sudo ss -tlnp
```

This shows all TCP ports that are listening. Write down what you see -- we'll compare later.

**3.** Check if UFW is running:

```bash
sudo ufw status
```

Probably says `Status: inactive`. That means no firewall. Everything is open.

**4.** Check OpenClaw's current status:

```bash
openclaw gateway status
```

**5.** Check if you have any `.env` files with secrets in them:

```bash
ls -la ~/openclaw-deploy/.env 2>/dev/null && echo "Found .env file" || echo "No .env file"
```

**6.** Check your current `openclaw.json` for inline secrets:

```bash
grep -i "api_key\|token\|secret\|password" ~/openclaw-deploy/openclaw.json 2>/dev/null
```

If you see actual API key values in that output (not SecretRef objects) -- that's exactly what we're about to fix.

---

## Part 2: Configure UFW Firewall

**7.** First, make sure UFW is installed:

```bash
sudo apt update && sudo apt install ufw -y
```

**8.** Before we enable the firewall, we need to think carefully. **What happens if we enable the firewall without allowing SSH first?**

Think about it.

...

We'd lock ourselves out. The firewall would block all incoming traffic, including our SSH connection. We'd have to use the VPS provider's web console to fix it. Let's not do that.

**9.** Set the defaults and allow SSH:

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22
```

> **Note:** We're allowing SSH from any IP here (not restricting to a specific IP). This is simpler and works with dynamic home IPs. SSH key authentication (from Module 3) protects you -- password brute-forcing won't work if password auth is disabled.

**10.** Enable the firewall:

```bash
sudo ufw enable
```

Type `y` when it warns about disrupting SSH connections. Since we just added the SSH rule, you're safe.

**11.** Verify:

```bash
sudo ufw status verbose
```

You should see:

```
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)

To                         Action      From
--                         ------      ----
22                         ALLOW IN    Anywhere
22 (v6)                    ALLOW IN    Anywhere (v6)
```

Your server just became invisible to port scanners on everything except SSH. And because OpenClaw runs natively, its gateway port (18789) is now blocked from outside by UFW -- no extra work needed.

---

## Part 3: Enable Automatic Security Updates

**12.** Install and configure unattended-upgrades:

```bash
sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure -plow unattended-upgrades
```

Select **Yes** when prompted.

**13.** Verify it's configured:

```bash
cat /etc/apt/apt.conf.d/20auto-upgrades
```

You should see:

```
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
```

One less thing to remember. Security patches now install themselves.

---

## Part 4: Create the Secrets Directory

**14.** Set up the directory structure:

```bash
cd ~/openclaw-deploy
mkdir -p secrets
chmod 700 secrets
```

**15.** Verify permissions:

```bash
ls -la | grep secrets
```

You should see `drwx------` -- read/write/execute for the owner only.

---

## Part 5: Create Your Secret Files

**16.** Create a secret file for each API key your bot uses. Replace the placeholder values with your real keys:

```bash
echo -n "your-actual-anthropic-api-key" > secrets/anthropic_api_key
```

If you have other secrets (GitHub token, etc.), create files for each:

```bash
echo -n "your-github-token" > secrets/github_token
```

> **Important:** The `-n` flag prevents a trailing newline. A newline at the end of your API key will cause mysterious "invalid API key" errors. Ask me how I know.

**17.** Lock down permissions:

```bash
chmod 600 secrets/*
```

**18.** Verify:

```bash
ls -la secrets/
```

Every file should show `-rw-------`. Only the owner can read or write.

---

## Part 6: Update openclaw.json to Use SecretRef

This is the key step for native OpenClaw. Instead of having API keys as plain strings in your config, you replace them with SecretRef objects that point to the files you just created.

**19.** Open your `openclaw.json`:

```bash
nano ~/openclaw-deploy/openclaw.json
```

**20.** Find any section where you have an API key as a plain string, like:

```json
{
  "anthropic": {
    "api_key": "sk-ant-api03-your-actual-key"
  }
}
```

Replace it with a SecretRef:

```json
{
  "anthropic": {
    "api_key": {
      "source": "file",
      "id": "/home/ubuntu/openclaw-deploy/secrets/anthropic_api_key"
    }
  }
}
```

Do the same for every secret in your config. Common ones:

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

> **Adjust the username in the path** if your VPS user is not `ubuntu`. For example, if you're using the `openclaw` user, the path would be `/home/openclaw/openclaw-deploy/secrets/anthropic_api_key`.

**21.** Save and close the file.

---

## Part 7: Set Up Docker Secrets for Support Services

For Docker support containers (cloudflared, Uptime Kuma, kill switch), we use Docker Compose secrets.

**22.** If you have a Cloudflare tunnel token (from Module 8, or if you're setting up ahead):

```bash
echo -n "eyJhIjoiNzA2...your-actual-token" > secrets/cloudflare_tunnel_token
chmod 600 secrets/cloudflare_tunnel_token
```

**23.** Update your `docker-compose.yml` to use secrets for any support containers. Here's what the cloudflared service should look like:

```yaml
services:
  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cloudflared
    restart: unless-stopped
    command: >
      sh -c 'tunnel --no-autoupdate run --token $$(cat /run/secrets/cloudflare_tunnel_token)'
    secrets:
      - cloudflare_tunnel_token
    networks:
      - openclaw-net

secrets:
  cloudflare_tunnel_token:
    file: ./secrets/cloudflare_tunnel_token
```

Notice: **no ports section** for cloudflared (it makes outbound connections only). For any container that *does* expose ports, always use the `127.0.0.1:` prefix:

```yaml
  uptime-kuma:
    ports:
      - "127.0.0.1:3001:3001"    # CRITICAL: localhost only!
```

**24.** Create a `.env.secrets` file for any support service that needs environment variables but doesn't support `/run/secrets/`:

```bash
cat > ~/openclaw-deploy/.env.secrets << 'EOF'
# Support service secrets -- DO NOT commit to git
# Used by services that don't support Docker Compose secrets natively
EOF
chmod 600 ~/openclaw-deploy/.env.secrets
```

**25.** Make sure `.env.secrets` and the secrets directory are in `.gitignore`:

```bash
echo "secrets/" >> ~/openclaw-deploy/.gitignore
echo ".env.secrets" >> ~/openclaw-deploy/.gitignore
```

---

## Part 8: Restart and Verify Everything Works

**26.** Restart OpenClaw with the new SecretRef configuration:

```bash
openclaw gateway restart
```

**27.** Check it's running:

```bash
openclaw gateway status
```

**28.** Verify the gateway is listening only locally (or is blocked by UFW from outside):

```bash
sudo ss -tlnp | grep 18789
```

You should see OpenClaw listening. Since it's a native process, UFW blocks external access. No `127.0.0.1:` prefix needed -- the firewall handles it.

**29.** If you have Docker support containers running, restart them:

```bash
cd ~/openclaw-deploy
docker compose up -d
```

**30.** Check Docker containers are running:

```bash
docker compose ps
```

**31.** The big test -- verify no secrets are visible in Docker container metadata:

```bash
docker inspect $(docker ps -q | head -1) 2>/dev/null | grep -i "anthropic\|api_key\|token" || echo "No secrets found in docker inspect -- good!"
```

**32.** Verify your bot actually works. Send it a test message via Telegram and confirm you get a response.

**33.** Check the OpenClaw logs:

```bash
openclaw gateway logs --tail 50
```

Look for successful startup messages. If there are errors about missing API keys, double-check that your secret files don't have trailing newlines (the `-n` flag issue) and that the paths in `openclaw.json` SecretRef entries are correct.

---

## Part 9: Verify the Security Lockdown

**34.** Check UFW is still active:

```bash
sudo ufw status
```

**35.** Check what ports Docker is listening on:

```bash
sudo ss -tlnp | grep docker
```

For Docker containers, you should see ports bound to `127.0.0.1` only, not `0.0.0.0`. If you see `0.0.0.0`, that port is exposed to the internet despite UFW.

**36.** Run a quick mental audit:

- Firewall active? Check.
- Auto-updates enabled? Check.
- OpenClaw secrets in SecretRef files, not inline? Check.
- Docker support container secrets in compose secrets? Check.
- File permissions locked down? Check.
- Docker ports bound to 127.0.0.1? Check.

That's two legs of the lethal trifecta addressed. The third leg (monitoring) comes in Module 9.

---

## What Just Happened?

Let's trace what you built:

1. **UFW firewall** blocks all incoming traffic except SSH -- works for native OpenClaw out of the box
2. **Automatic updates** keep the OS patched
3. **Secret files** live in `~/openclaw-deploy/secrets/` with `600` permissions
4. **The secrets directory** has `700` permissions
5. **OpenClaw's `openclaw.json`** uses SecretRef to read secrets from files -- no environment variables
6. **Docker Compose** uses file-based secrets for support containers like cloudflared
7. **`docker inspect`** shows NOTHING about the secrets in support containers
8. **Docker port bindings** use `127.0.0.1:` to prevent bypassing UFW
9. **Non-secret config** stays in `.env` or `openclaw.json` where it belongs
10. **OpenClaw gateway restart** picks up the new SecretRef configuration

---

## Troubleshooting

**"I got locked out of SSH after enabling UFW"**

Use your VPS provider's web console (most providers have a browser-based SSH option):
1. Log into the provider's dashboard
2. Use the web-based terminal
3. Run `sudo ufw allow 22` and `sudo ufw enable`

**"OpenClaw can't find my secrets after switching to SecretRef"**

Check three things:
1. The path in `openclaw.json` matches the actual file location exactly (use `ls -la` to verify)
2. The secret files have the right permissions (`chmod 600`)
3. The secret files don't have trailing newlines (recreate with `echo -n`)

**"My bot can't connect to APIs after enabling UFW"**

UFW allows all outbound by default, so this shouldn't happen. Verify with `sudo ufw status verbose` and check that outgoing is set to "allow."

**"docker inspect still shows secrets for a support container"**

Make sure you're using the `secrets:` section in docker-compose.yml, not the `environment:` section. If secrets are in *both* places, they'll still appear via the environment section.

**"openclaw gateway restart fails"**

Check the JSON syntax in `openclaw.json`. A missing comma or bracket in the SecretRef objects will cause a parse error. Use `python3 -m json.tool ~/openclaw-deploy/openclaw.json` to validate the JSON.

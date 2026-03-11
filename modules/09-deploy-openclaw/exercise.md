# Exercise 9: Ship It -- Full Docker Compose Deployment

## What We're Doing

We're building the complete OpenClaw stack from scratch. By the end of this exercise, you'll have five containers running, a working AI agent, and the ability to message it from your phone and get a response. This is the victory lap.

## Prerequisites

Before starting, make sure you have:
- SSH access to your VPS as the `openclaw` user
- Docker and Docker Compose installed (Module 4)
- UFW configured with deny-all inbound except SSH (Module 5)
- Secret files created in a `secrets/` directory (Module 6)
- Cloudflare Tunnel configured in the dashboard (Module 7)
- WhatsApp Business app with webhooks pointing at your tunnel URL (Module 8)

SSH into your server now. Everything from here happens on your VPS.

```bash
ssh openclaw@your-server-ip
```

---

## Step 1: Create the Project Directory

Let's set up the directory structure. Everything lives under `~/openclaw-stack/`.

```bash
mkdir -p ~/openclaw-stack/{config/searxng,config/google,config/killswitch,data,repos}
cd ~/openclaw-stack
```

Verify the structure:

```bash
find ~/openclaw-stack -type d | sort
```

You should see:

```
/home/openclaw/openclaw-stack
/home/openclaw/openclaw-stack/config
/home/openclaw/openclaw-stack/config/google
/home/openclaw/openclaw-stack/config/killswitch
/home/openclaw/openclaw-stack/config/searxng
/home/openclaw/openclaw-stack/data
/home/openclaw/openclaw-stack/repos
```

If you already created the `secrets/` directory during Module 6, it should be here too. If not:

```bash
mkdir -p ~/openclaw-stack/secrets
```

## Step 2: Move Your Secrets Into Place

If you followed Module 6, your secret files might be in a different location. Move or copy them into the project:

```bash
# If your secrets are elsewhere, copy them in.
# Each file should contain just the raw secret value -- no quotes, no newlines.
# Example (don't run this literally -- use your actual values):
# echo -n "sk-ant-your-key-here" > ~/openclaw-stack/secrets/anthropic_api_key

ls -la ~/openclaw-stack/secrets/
```

You should see these files (at minimum):

```
anthropic_api_key
whatsapp_access_token
whatsapp_verify_token
whatsapp_app_secret
tunnel_token
```

Optional (if you set up these integrations):

```
github_token
notion_api_key
kill_secret
```

Lock down permissions:

```bash
chmod 600 ~/openclaw-stack/secrets/*
```

> **Pro tip:** If you haven't set up GitHub or Notion yet, create empty placeholder files for now. Docker Compose will fail if it references a secret file that doesn't exist. You can always put the real values in later.
>
> ```bash
> touch ~/openclaw-stack/secrets/github_token
> touch ~/openclaw-stack/secrets/notion_api_key
> touch ~/openclaw-stack/secrets/kill_secret
> chmod 600 ~/openclaw-stack/secrets/*
> ```

## Step 3: Create the SearXNG Config

SearXNG needs a settings file. This is minimal -- just enough to tell it to accept JSON requests from OpenClaw.

```bash
nano ~/openclaw-stack/config/searxng/settings.yml
```

Paste this:

```yaml
use_default_settings: true
server:
  secret_key: "replace-with-a-random-string"
  bind_address: "0.0.0.0"
search:
  formats: [html, json]
```

Replace `replace-with-a-random-string` with an actual random string. You can generate one with:

```bash
openssl rand -hex 16
```

Copy the output and paste it as the `secret_key` value. This key is used for SearXNG's internal session management -- it doesn't leave the container.

Save and exit nano (Ctrl+O, Enter, Ctrl+X).

## Step 4: Create the .env File

This file holds non-secret configuration. Create it:

```bash
nano ~/openclaw-stack/.env
```

Paste this:

```bash
PUID=1000
PGID=1000
TZ=UTC
SEARXNG_BASE_URL=http://searxng:8080
```

Change `TZ` to your actual timezone if you want timestamps in your local time (e.g., `TZ=Europe/Istanbul` or `TZ=America/New_York`).

To check your host user's UID and GID:

```bash
id
```

The `uid` and `gid` values should match `PUID` and `PGID`. For the first non-root user on most systems, these are both `1000`.

Save and exit.

## Step 5: Build the docker-compose.yml

This is the big one. We'll build it service by service so you understand every line.

```bash
nano ~/openclaw-stack/docker-compose.yml
```

Paste the complete file:

```yaml
version: "3.8"
services:
  openclaw:
    image: openclaw/openclaw:latest
    container_name: openclaw
    restart: unless-stopped
    env_file: .env
    secrets:
      - anthropic_api_key
      - whatsapp_access_token
      - whatsapp_verify_token
      - whatsapp_app_secret
      - github_token
      - notion_api_key
    volumes:
      - ./config:/home/openclaw/.openclaw
      - ./config/google:/home/openclaw/.google
      - ./data:/home/openclaw/data
      - ./repos:/home/openclaw/repos
    ports:
      - "127.0.0.1:3000:3000"
    networks:
      - openclaw-net
    depends_on:
      - searxng
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cloudflared
    restart: unless-stopped
    command: tunnel run
    secrets:
      - tunnel_token
    networks:
      - openclaw-net
    depends_on:
      - openclaw

  searxng:
    image: searxng/searxng:latest
    container_name: searxng
    restart: unless-stopped
    ports:
      - "127.0.0.1:8080:8080"
    volumes:
      - ./config/searxng:/etc/searxng
    networks:
      - openclaw-net

  uptime-kuma:
    image: louislam/uptime-kuma:latest
    container_name: uptime-kuma
    restart: unless-stopped
    ports:
      - "127.0.0.1:3001:3001"
    volumes:
      - uptime-kuma-data:/app/data
    networks:
      - openclaw-net

  killswitch:
    image: nginx:alpine
    container_name: killswitch
    restart: unless-stopped
    secrets:
      - kill_secret
    ports:
      - "127.0.0.1:3999:80"
    volumes:
      - ./config/killswitch/nginx.conf:/etc/nginx/conf.d/default.conf
      - /var/run/docker.sock:/var/run/docker.sock
    networks:
      - openclaw-net

secrets:
  anthropic_api_key:
    file: ./secrets/anthropic_api_key
  whatsapp_access_token:
    file: ./secrets/whatsapp_access_token
  whatsapp_verify_token:
    file: ./secrets/whatsapp_verify_token
  whatsapp_app_secret:
    file: ./secrets/whatsapp_app_secret
  github_token:
    file: ./secrets/github_token
  notion_api_key:
    file: ./secrets/notion_api_key
  tunnel_token:
    file: ./secrets/tunnel_token
  kill_secret:
    file: ./secrets/kill_secret

networks:
  openclaw-net:
    driver: bridge

volumes:
  uptime-kuma-data:
```

Save and exit.

**Before we go further:** Take thirty seconds and re-read the file top to bottom. Can you trace the flow? A WhatsApp message hits Cloudflare, gets forwarded through the tunnel to `cloudflared`, which sends it to `openclaw` on port 3000. OpenClaw processes it, maybe queries `searxng` for a web search, then sends the response back. Meanwhile, `uptime-kuma` watches everything, and `killswitch` waits quietly in case you need to hit the brakes.

That mental model -- being able to trace a request through your system -- is worth more than memorizing any single command.

## Step 6: Create a Placeholder Killswitch Config

The killswitch needs an nginx config file to exist, or the container won't start. We'll build the real one in Module 11. For now, create a placeholder:

```bash
nano ~/openclaw-stack/config/killswitch/nginx.conf
```

Paste this minimal config:

```nginx
server {
    listen 80;
    location / {
        return 404 'Not configured yet. See Module 11.';
        add_header Content-Type text/plain;
    }
}
```

Save and exit.

## Step 7: Pull the Images

Before starting, let's download all the container images. This can take a few minutes depending on your server's internet speed.

```bash
cd ~/openclaw-stack
docker compose pull
```

**What do you think will happen?** Docker will download five images from Docker Hub -- one for each service. You'll see progress bars for each layer being pulled.

Watch the output. You should see all five images being pulled:

```
[+] Pulling 5/5
 ✔ openclaw Pulled
 ✔ cloudflared Pulled
 ✔ searxng Pulled
 ✔ uptime-kuma Pulled
 ✔ killswitch Pulled
```

If any image fails to pull, check your internet connection and try again. The most common issue is a typo in the image name.

## Step 8: Launch the Stack

This is the moment. Deep breath.

```bash
docker compose up -d
```

The `-d` flag runs everything in the background. You should see:

```
[+] Running 6/6
 ✔ Network openclaw-net       Created
 ✔ Volume uptime-kuma-data    Created
 ✔ Container searxng          Started
 ✔ Container uptime-kuma      Started
 ✔ Container killswitch       Started
 ✔ Container openclaw         Started
 ✔ Container cloudflared      Started
```

Notice the start order: `searxng` starts first (because `openclaw` depends on it), then `openclaw`, then `cloudflared` (because it depends on `openclaw`). Docker Compose handles this automatically based on the `depends_on` declarations.

## Step 9: Verify Everything Is Running

Check the status of all containers:

```bash
docker compose ps
```

You should see all five containers with `Up` status:

```
NAME           IMAGE                              STATUS
cloudflared    cloudflare/cloudflared:latest       Up
killswitch     nginx:alpine                       Up
openclaw       openclaw/openclaw:latest           Up (healthy)
searxng        searxng/searxng:latest             Up
uptime-kuma    louislam/uptime-kuma:latest        Up
```

If any container shows `Restarting` or `Exit`, check its logs:

```bash
docker compose logs <service-name>
```

Common issues:
- **openclaw restarting** -- usually a missing or invalid secret file. Check that all files in `secrets/` exist and have content.
- **cloudflared restarting** -- invalid tunnel token. Verify the value in `secrets/tunnel_token` matches what Cloudflare gave you.
- **searxng errors** -- usually a YAML syntax error in `settings.yml`. Check indentation carefully.
- **killswitch won't start** -- missing nginx.conf. Make sure you created it in Step 6.

## Step 10: Check the Logs

Let's peek at each service to make sure they're happy:

```bash
# OpenClaw -- should show startup messages
docker compose logs openclaw | tail -20

# Cloudflared -- should show "Connection registered" or similar
docker compose logs cloudflared | tail -10

# SearXNG -- should show it's listening on port 8080
docker compose logs searxng | tail -10
```

If you see errors, this is where you debug. The logs tell you exactly what's wrong.

> **Pro tip:** If you want to watch logs live as things happen (useful during onboarding), use the `-f` flag:
> ```bash
> docker compose logs -f openclaw
> ```
> Press Ctrl+C to stop following.

## Step 11: Run the Onboarding

OpenClaw needs a one-time interactive setup. This is where you configure your AI model, confirm your integrations, and set preferences.

```bash
docker compose exec openclaw openclaw onboard
```

Follow the prompts. The onboarding wizard will:
1. Detect your secrets automatically (from `/run/secrets/`)
2. Ask you to choose an AI model (Claude Sonnet is a great default)
3. Walk you through enabling integrations
4. Let you customize your agent's behavior

Take your time here. The choices you make are saved to `config/` and can be changed later.

## Step 12: Send Your First Message

Open WhatsApp on your phone. Find the number you configured in Module 8 (the Meta test number or your WhatsApp Business number).

Send a message. Something simple:

> Hey, are you there?

Now watch the logs:

```bash
docker compose logs -f openclaw
```

You should see the incoming webhook, the message being processed, the Claude API call, and the response being sent back.

**Check your phone.**

If you see a response -- congratulations. Your AI agent is running on your own server, responding to your WhatsApp messages through a Cloudflare Tunnel, powered by Claude, with secrets properly managed and zero open ports to the internet. You built this.

If you don't see a response, don't panic. Check:
1. **Cloudflare Tunnel** -- Is it connected? `docker compose logs cloudflared`
2. **Webhook URL** -- Is it correct in the Meta dashboard? It should be `https://your-subdomain.your-domain.com/webhook` (or whatever you configured in Module 8)
3. **OpenClaw logs** -- Is it receiving the webhook? `docker compose logs -f openclaw`
4. **WhatsApp test number** -- Are you messaging the right number?

## Step 13: Try a Few Things

Now that it's working, give it a real workout:

```
Ask it a factual question (triggers web search through SearXNG):
"What's the current weather in Istanbul?"

Ask it something conversational:
"Explain Docker Compose to me like I'm 10 years old"

Ask it to do math:
"What's 15% of 847?"
```

Watch the logs as each message comes in. You can see the entire flow -- message received, AI processing, search queries (if applicable), response sent.

## Step 14: Learn the Daily Operations

You're going to use these commands regularly. Practice each one now:

```bash
# Check what's running
docker compose ps

# Check resource usage
docker stats --no-stream

# Restart just OpenClaw (e.g., after changing config)
docker compose restart openclaw

# Stop the entire stack
docker compose down

# Start it again
docker compose up -d

# Update all images to latest versions
docker compose pull && docker compose up -d
```

Run each of these. Get comfortable with the flow. The `down` + `up -d` cycle is completely safe -- your data persists in the volumes.

> **Pro tip:** `docker stats --no-stream` shows a single snapshot of resource usage. Without `--no-stream`, it updates continuously like `top`. On a 2 GB RAM Lightsail instance, expect the full stack to use about 500-800 MB of RAM. If you're above 1.5 GB, something might be off.

---

## What Just Happened?

Let's take stock:

1. **You created a directory structure** -- a single `~/openclaw-stack/` directory containing everything your AI agent needs
2. **You assembled a docker-compose.yml** -- five services, one network, proper secrets, health checks, dependency ordering
3. **You configured SearXNG** -- a private search engine that your AI agent uses instead of calling Google directly
4. **You pulled and started five containers** -- with one command
5. **You ran onboarding** -- configuring your AI agent interactively inside the container
6. **You sent your first message** -- and got a response from Claude, through WhatsApp, through a Cloudflare Tunnel, to your own server

That's a real deployment. Not a tutorial. Not a sandbox. A production system running on infrastructure you control.

---

## Try This (Optional Experiments)

**Experiment 1: Inspect the network.** Run `docker network inspect openclaw-net` and find the IP addresses assigned to each container. These are internal IPs on the bridge network -- not accessible from outside.

**Experiment 2: Shell into a container.** Run `docker compose exec searxng sh` and try `curl http://openclaw:3000/health`. You're making a request from inside SearXNG to OpenClaw, using the Docker network. This is how the containers see each other.

**Experiment 3: Test SearXNG directly.** From your VPS, run:
```bash
curl "http://127.0.0.1:8080/search?q=docker+compose&format=json" | head -100
```
You should see JSON search results. This is what OpenClaw sees when it does a web search.

**Experiment 4: Check the health status.** Run `docker inspect openclaw | grep -A 5 "Health"`. You should see the healthcheck status and recent results.

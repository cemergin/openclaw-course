# Lesson 9: Ship It -- Full Docker Compose Deployment

## The Assembly Line

You know that scene in every heist movie where the team finally gathers in the warehouse, the plan goes up on the whiteboard, and someone says "okay, here's how it all fits together"?

That's this module.

You've spent eight modules building individual skills -- a VPS here, Docker there, secrets over here, a tunnel over there. Every one of those modules was a piece of the puzzle. And right now, the puzzle pieces are scattered across your server, waiting for someone to snap them together.

That someone is you. And the glue is a single file: `docker-compose.yml`.

## The Architecture: What We're Building

Before we write a single line of YAML, let's look at the big picture. Here's how your stack works when a message arrives:

```
Your Phone (WhatsApp)
    |
    v
Meta's Servers (webhook)
    |
    v
Cloudflare Network
    |
    v  (through Cloudflare Tunnel)
cloudflared container -----> openclaw container -----> Claude API
    (port 3000)                                        (external)
                                |
                                v
                          searxng container
                            (web search)

uptime-kuma container (watches everything)
killswitch container (emergency stop)
```

Five containers. One network. Zero open ports to the internet (remember Module 7?). Let's meet each one.

## The Five Services

### 1. OpenClaw -- The Brain

This is the star of the show. OpenClaw is your AI agent -- it receives messages from WhatsApp, sends them to Claude (or whatever AI model you've chosen), and sends the response back. It also handles integrations like web search, GitHub, Notion, and more.

It needs:
- **Your secrets** -- API keys for Claude, WhatsApp tokens, and any integration keys
- **Config directory** -- where OpenClaw stores its settings and Google credentials
- **Data directory** -- where it keeps conversation history and other persistent data
- **Repos directory** -- where it clones GitHub repos when you use that integration
- **Port 3000** -- bound to `127.0.0.1` so only the tunnel can reach it
- **Network access** to SearXNG for web searches

### 2. Cloudflared -- The Tunnel

The invisible bridge between your server and the internet. It creates an outbound connection to Cloudflare's network, and traffic flows through that connection. Your server never opens an inbound port.

It needs:
- **The tunnel token** -- stored as a Docker secret
- **Network access** to OpenClaw (so it can forward incoming webhook requests)
- **Nothing else** -- no volumes, no ports, no config files. It's beautifully simple.

### 3. SearXNG -- The Search Engine

A self-hosted, privacy-respecting search engine. When you ask your AI agent to search the web, it uses SearXNG instead of hitting Google directly. This means no tracking, no API key for a search service, and it works even if commercial search APIs change their pricing.

It needs:
- **A settings file** -- basic config telling it to accept JSON requests
- **Port 8080** -- bound to `127.0.0.1` (only OpenClaw needs to reach it)
- **Network access** to the internet (for fetching search results)

### 4. Uptime Kuma -- The Watchdog

A self-hosted monitoring tool. It watches your other services and alerts you when something goes down. We'll configure it properly in Module 10, but we're deploying it now because it's part of the stack.

It needs:
- **A data volume** -- for storing monitoring history and configuration
- **Port 3001** -- bound to `127.0.0.1` (you'll access it through the tunnel)
- **Network access** to other containers (so it can check their health)

### 5. Killswitch -- The Emergency Stop

An nginx container that exposes a secret URL. Hit that URL from your phone and it stops the OpenClaw container. We'll build the full kill switch in Module 11, but the container goes in now.

It needs:
- **An nginx config** -- defining the kill endpoint
- **The kill secret** -- so random people can't shut down your bot
- **Docker socket access** -- so it can actually stop other containers
- **Port 3999** -- bound to `127.0.0.1` (accessed through the tunnel)

## The Compose File: Line by Line

Let's build this thing. Here's the complete file, and we'll walk through every section.

### Version and the Top Level

```yaml
version: "3.8"
```

This tells Docker Compose which version of the compose file format we're using. Version 3.8 supports everything we need: secrets, health checks, networks, depends_on. In newer versions of Docker Compose this line is technically optional, but including it is good practice -- it makes your intentions explicit.

### The OpenClaw Service

```yaml
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
```

That's a lot. Let's unpack it:

**`image: openclaw/openclaw:latest`** -- Pull the latest OpenClaw image from Docker Hub. The `latest` tag means you always get the newest version when you pull.

**`container_name: openclaw`** -- Give the container a friendly name instead of a random one. This makes logs and `docker exec` commands easier.

**`restart: unless-stopped`** -- If the container crashes or the server reboots, Docker restarts it automatically. The only time it stays stopped is if you explicitly run `docker compose stop openclaw`. This is what you want for a service that should be always on.

**`env_file: .env`** -- Load non-secret configuration from a `.env` file. Things like `PUID`, `PGID`, timezone. These aren't sensitive -- they're just config that's easier to manage in a file than inline.

**`secrets`** -- This is the Docker Secrets approach from Module 6. Each secret is a separate file in the `secrets/` directory, mounted read-only at `/run/secrets/<name>` inside the container. The key difference from `.env`: these values don't show up in `docker inspect`, logs, or `/proc`. They're actually secret.

**`volumes`** -- Four bind mounts:
- `./config` maps to OpenClaw's settings directory
- `./config/google` maps to where Google credentials live
- `./data` maps to conversation history and persistent data
- `./repos` maps to where GitHub repos get cloned

All of these are directories on your host machine. If you destroy and recreate the container, your data survives.

**`ports: "127.0.0.1:3000:3000"`** -- Expose port 3000, but only to localhost. Remember Module 4: the `127.0.0.1:` prefix is what keeps this port off the public internet. Cloudflare Tunnel connects to it from inside the server.

**`networks: openclaw-net`** -- Join the shared network so all containers can talk to each other by name.

**`depends_on: searxng`** -- Don't start OpenClaw until SearXNG is running. This ensures the search engine is available when OpenClaw tries to use it.

**`healthcheck`** -- Docker periodically hits `http://localhost:3000/health` inside the container. If it fails three times in a row (with 30-second intervals and 10-second timeouts), Docker marks the container as unhealthy. This is useful for monitoring and for other services that depend on OpenClaw.

### The Cloudflared Service

```yaml
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
```

Notice how clean this is compared to OpenClaw. Cloudflared is simple:

**`command: tunnel run`** -- Override the default container command to run the tunnel. The tunnel token (mounted as a secret) tells it which tunnel to use and where to route traffic.

**`secrets: tunnel_token`** -- The only secret it needs. This token came from your Cloudflare dashboard in Module 7.

**`depends_on: openclaw`** -- Wait for OpenClaw to start before starting the tunnel. There's no point routing traffic to a service that isn't up yet.

No ports, no volumes. The tunnel is an outbound connection -- it doesn't need to listen on any port.

### The SearXNG Service

```yaml
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
```

SearXNG is your private search engine. OpenClaw queries it at `http://searxng:8080` (using the Docker network hostname), and SearXNG fetches results from Google, Bing, DuckDuckGo, and others -- aggregating them without tracking you.

The settings file we'll create tells SearXNG to accept JSON-formatted requests (which is how OpenClaw queries it) and sets a secret key for session management.

### The Uptime Kuma Service

```yaml
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
```

Notice the volume here is different from the others. Instead of a bind mount (`./something:/path`), it uses a named volume (`uptime-kuma-data:/app/data`). Named volumes are managed by Docker itself -- Docker decides where to store them on disk. This is fine for application data that you don't need to directly edit from the host.

We'll configure Uptime Kuma in Module 10, but for now it's deployed and accessible at `127.0.0.1:3001` through the tunnel.

### The Killswitch Service

```yaml
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
```

This one's interesting. It's a tiny nginx web server that serves a single purpose: provide a URL that stops the OpenClaw container.

**`/var/run/docker.sock:/var/run/docker.sock`** -- This mounts the Docker socket into the container, giving it the ability to control other containers. Yes, this is powerful and somewhat dangerous -- it's essentially giving this container root-level Docker access. That's why the kill secret exists: to make sure only you can trigger it. We'll build the full nginx config in Module 11.

## The Glue: Secrets, Networks, and Volumes

After the services, we declare the resources they share:

```yaml
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

**Secrets** -- Each entry maps a secret name to a file on disk. When a service declares `secrets: [anthropic_api_key]`, Docker mounts the contents of `./secrets/anthropic_api_key` at `/run/secrets/anthropic_api_key` inside the container. One file per secret. Clean. Auditable. Invisible to `docker inspect`.

**Networks** -- One bridge network called `openclaw-net`. All services join it. They can reach each other by service name (e.g., `http://searxng:8080`). Nothing outside this network can reach them directly.

**Volumes** -- We only declare `uptime-kuma-data` here because it's a named volume. The bind mounts (like `./config:/home/openclaw/.openclaw`) don't need to be declared separately -- they're just host paths.

## The .env File: Non-Secret Config

Not everything is a secret. Some configuration values are just... configuration. User IDs, timezone, feature flags. These go in `.env`:

```bash
PUID=1000
PGID=1000
TZ=UTC
SEARXNG_BASE_URL=http://searxng:8080
```

**`PUID` and `PGID`** -- The user and group ID that OpenClaw runs as inside the container. Setting these to match your host user (usually 1000 for the first non-root user) prevents file permission issues with bind-mounted volumes.

**`TZ`** -- Timezone. Set this to your local timezone (e.g., `Europe/Istanbul`, `America/New_York`) so logs and timestamps make sense.

**`SEARXNG_BASE_URL`** -- Tells OpenClaw where to find SearXNG. Since they're on the same Docker network, we use the service name as the hostname.

> **Pro tip:** How do you decide what goes in `.env` vs `secrets/`? Simple rule: if someone seeing the value could compromise your account, steal money, or impersonate you -- it's a secret. Everything else is config. A timezone is config. An Anthropic API key is a secret.

## The Directory Structure

Here's what your project directory looks like on the host:

```
~/openclaw-stack/
├── docker-compose.yml          # The orchestra conductor
├── .env                        # Non-secret configuration
├── secrets/                    # One file per secret (chmod 600)
│   ├── anthropic_api_key
│   ├── whatsapp_access_token
│   ├── whatsapp_verify_token
│   ├── whatsapp_app_secret
│   ├── github_token
│   ├── notion_api_key
│   ├── tunnel_token
│   └── kill_secret
├── config/                     # Configuration files
│   ├── google/                 # Google OAuth credentials
│   ├── searxng/
│   │   └── settings.yml        # SearXNG configuration
│   └── killswitch/
│       └── nginx.conf          # Kill switch endpoint config
├── data/                       # OpenClaw persistent data
└── repos/                      # Cloned GitHub repos
```

Everything lives in one directory. You can back it up, move it to another server, or version-control the non-secret parts. This is the power of Docker Compose -- your entire infrastructure is a directory.

## Daily Operations: The Commands You'll Actually Use

Once your stack is running, here's your daily toolkit:

```bash
# Start everything (the command you'll use most)
docker compose up -d

# Stop everything gracefully
docker compose down

# Restart a single service (without touching the others)
docker compose restart openclaw

# Update to latest versions
docker compose pull && docker compose up -d

# Check what's running
docker compose ps

# Follow logs for one service (Ctrl+C to stop)
docker compose logs -f openclaw

# Follow logs for everything
docker compose logs -f

# Open a shell inside a running container
docker compose exec openclaw bash

# Check resource usage (CPU, RAM, network)
docker stats
```

> **Pro tip:** The most common operation you'll do is check logs after something seems off. `docker compose logs -f openclaw` is your first stop for debugging. The `-f` flag means "follow" -- new log lines appear in real time. Press Ctrl+C to stop following without stopping the container.

These commands all need to be run from the directory that contains your `docker-compose.yml` -- in our case, `~/openclaw-stack/`. If you're somewhere else, either `cd` there first or use the `-f` flag: `docker compose -f ~/openclaw-stack/docker-compose.yml ps`.

## The Onboarding Flow

Once your stack is running, OpenClaw needs a one-time setup. The `openclaw onboard` command walks you through it interactively:

```bash
docker compose exec openclaw openclaw onboard
```

This will ask you to:
1. Choose your AI model (Claude is recommended)
2. Confirm your API key is working
3. Set up your default integrations
4. Configure your personal preferences

It reads your secrets from `/run/secrets/` automatically -- you don't need to enter API keys again. The configuration gets saved to the `config/` volume, so it persists across container restarts.

## The Bigger Picture

Take a step back and appreciate what you've built. You have:

- A VPS on AWS with SSH access and a firewall (Modules 2-3, 5)
- Docker running containerized services (Module 4)
- Secrets stored properly, not in environment variables (Module 6)
- A Cloudflare Tunnel exposing nothing to the internet (Module 7)
- WhatsApp configured to deliver messages through that tunnel (Module 8)
- Five containers working together, defined in a single file (this module)

The security posture alone is genuinely impressive: zero open ports, secrets invisible to inspection, all traffic routed through Cloudflare's edge network. Most hobby deployments don't come close to this.

And the operational model is dead simple: one command to start, one to stop, one to update. The complexity is in the setup -- the daily experience is effortless.

Now let's actually build it.

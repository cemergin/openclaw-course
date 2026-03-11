# Exercise: Setting Up Cloudflare Tunnel

## What We're Doing

You're going to create a Cloudflare Tunnel that routes traffic to your VPS without opening a single inbound port. By the end, you'll have a working tunnel with a public URL, and you'll prove your server is invisible by scanning it.

## Prerequisites

- Your VPS is running with Docker and Docker Compose (Modules 2-4)
- UFW is configured to deny all inbound except SSH (Module 5)
- You have a credit/debit card for domain purchase (~$10/year) -- or an existing domain you can transfer
- A web browser for the Cloudflare dashboard

---

## Step 1: Create a Cloudflare Account

Head to [dash.cloudflare.com](https://dash.cloudflare.com) and sign up for a free account. Use a real email -- you'll need to verify it.

The free plan is all you need. Cloudflare will try to upsell you on paid plans during onboarding -- politely decline. The free tier includes:

- Tunnel support (unlimited tunnels)
- DNS management
- DDoS protection
- TLS certificates

All free. Cloudflare's business model is selling enterprise features to big companies, so the basics are genuinely free.

---

## Step 2: Get a Domain

You need a domain for the tunnel to route through. You have two options:

**Option A: Buy from Cloudflare (recommended).** Go to the Cloudflare dashboard, click **Domain Registration** in the sidebar, then **Register Domain**. Search for something short and cheap -- `.com` domains run about $10/year, and some newer TLDs (`.dev`, `.xyz`) can be even cheaper. Cloudflare sells domains at cost with no markup.

**Option B: Transfer an existing domain.** If you already own a domain, you can add it to Cloudflare by clicking **Add a Site** on the dashboard. Cloudflare will give you two nameservers to set at your current registrar. This takes a few minutes to a few hours to propagate.

Whichever path you choose, you need your domain active in Cloudflare before continuing.

> **Pro tip:** Pick a domain you're okay using long-term. Your WhatsApp webhook URL will be tied to it, and changing it later means reconfiguring Meta's developer settings. Not hard, but annoying.

---

## Step 3: Create the Tunnel

Now the fun part.

1. In the Cloudflare dashboard, go to **Zero Trust** (in the left sidebar -- it might be labeled "Cloudflare One" or have a shield icon)
2. Navigate to **Networks** --> **Tunnels**
3. Click **Create a tunnel**
4. Select **Cloudflared** as the connector type
5. Name your tunnel something descriptive -- `openclaw` works great
6. Click **Save tunnel**

Cloudflare will now show you installation instructions for various platforms. We want the **Docker** option.

You'll see a command that looks something like:

```bash
docker run cloudflare/cloudflared:latest tunnel --no-autoupdate run --token eyJhIjoiNzA2...very-long-string
```

**Don't run this command directly.** We're going to put this in a Docker Compose file instead. But do copy the token -- that long string after `--token`. You'll need it in Step 5.

The token is the entire string starting with `eyJ`. It's long (usually 150+ characters). Copy the whole thing.

---

## Step 4: Add Public Hostname Routes

Before leaving the tunnel setup wizard, or by clicking on your tunnel and going to the **Public Hostname** tab, add your first route:

| Field | Value |
|---|---|
| **Subdomain** | `openclaw` |
| **Domain** | Select your domain from the dropdown |
| **Service Type** | `HTTP` |
| **URL** | `openclaw:3000` |

This tells Cloudflare: "When someone requests `openclaw.yourdomain.com`, forward the traffic through the tunnel to port 3000 of the Docker container named `openclaw`."

Notice the service URL is just `openclaw:3000` -- not `localhost:3000`. That's because `cloudflared` runs as a Docker container on the same network as OpenClaw, so it resolves the container name directly. This is Docker networking from Module 4 in action.

Before you click save -- **what do you think will happen if someone visits `random.yourdomain.com`?**

Hopefully you're thinking "404" -- and you'd be right. Any subdomain without a route gets a default 404 response. We'll verify this later.

Click **Save hostname** to add the route.

---

## Step 5: Add the Cloudflared Service to Docker Compose

SSH into your VPS and open your Docker Compose file. We're going to add `cloudflared` as a new service.

If you're working from the starter file, open it:

```bash
nano ~/openclaw/docker-compose.yml
```

Add the `cloudflared` service. Here's what you need (also available in `starter/tunnel-compose-snippet.yml`):

```yaml
  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cloudflared
    restart: unless-stopped
    command: tunnel run
    environment:
      - TUNNEL_TOKEN=your-actual-token-here
    networks:
      - openclaw-net
```

Replace `your-actual-token-here` with the token you copied in Step 3.

A few things to notice:

- **`command: tunnel run`** -- this tells cloudflared to run the tunnel using the token from the environment
- **`restart: unless-stopped`** -- if the tunnel crashes, Docker restarts it automatically
- **`networks: openclaw-net`** -- this puts cloudflared on the same Docker network as your other services, so it can reach them by container name
- **No port mappings** -- this container doesn't expose any ports. It doesn't need to. The whole point is that connections are outbound.

> **Pro tip:** In a production setup, you'd want to handle the tunnel token as a proper Docker secret (like we learned in Module 6) rather than an environment variable. For now, the environment variable gets us running. We'll tighten this up in Module 9 when we assemble the final compose file.

---

## Step 6: Start the Tunnel

Bring up the new service:

```bash
cd ~/openclaw
docker compose up -d cloudflared
```

Check that it's running:

```bash
docker compose logs cloudflared
```

You should see output like:

```
INF Starting tunnel tunnelID=xxxx-xxxx-xxxx
INF Connection registered connIndex=0 ...
INF Connection registered connIndex=1 ...
INF Connection registered connIndex=2 ...
INF Connection registered connIndex=3 ...
```

Four connections registered means the tunnel is up and healthy. Cloudflare establishes multiple connections for redundancy -- if one drops, traffic automatically routes through the others.

If you see errors about invalid tokens or authentication failures, double-check that you copied the entire token string. A missing character at the end is the most common issue.

---

## Step 7: Verify the Tunnel Works

Back in the Cloudflare dashboard, go to **Zero Trust** --> **Networks** --> **Tunnels**. Your tunnel should show as **HEALTHY** with a green indicator.

Now let's test from outside. On your *local machine* (not the VPS), run:

```bash
curl -I https://openclaw.yourdomain.com
```

You should get an HTTP response -- likely a `404` or `502` right now, because OpenClaw isn't running yet. That's fine! The important thing is that you *got a response*. That means:

1. Your DNS is routing correctly through Cloudflare
2. The tunnel is forwarding traffic to your VPS
3. Cloudflare is handling TLS (notice you used `https://` and it just worked -- no certificate setup needed)

If you get a connection timeout or DNS error, give it a few minutes -- DNS propagation can take up to 5 minutes for newly configured routes.

---

## Step 8: Prove Your Server Is Invisible

This is the satisfying part.

From your local machine, scan your VPS's public IP address:

```bash
nmap -Pn your.vps.ip.address
```

(Replace `your.vps.ip.address` with your actual VPS IP.)

**Before running this, what do you expect to see?**

If everything is configured correctly, you should see:

```
All 1000 scanned ports on your.vps.ip.address are filtered
```

Or possibly just SSH (port 22) showing as open, depending on your UFW configuration. But port 443? Closed. Port 80? Closed. Port 3000? Closed. Your VPS is a ghost.

If you don't have nmap installed, you can use an online port scanner like [YouGetSignal](https://www.yougetsignal.com/tools/open-ports/) or [CanYouSeeMe](https://canyouseeme.org/). Check port 443 -- it should be closed.

This is the moment. WhatsApp will be able to reach your server (through the tunnel), but port scanners see nothing. Your server is invisible to the internet while still being fully functional. That's the whole trick.

---

## What Just Happened?

Let's trace what you built:

1. **Cloudflare account + domain** -- gives you a DNS namespace to work with
2. **Tunnel** -- an authenticated, outbound-only connection from your VPS to Cloudflare's network
3. **Hostname route** -- maps `openclaw.yourdomain.com` to the OpenClaw container on your VPS
4. **cloudflared container** -- runs the tunnel client inside Docker, on the same network as your services
5. **Zero open ports** -- verified by port scan. Your server is invisible.

The connection flows outbound from your VPS. Cloudflare holds it open. When traffic arrives for your domain, Cloudflare routes it through the tunnel. Your firewall never had to open a port.

You just eliminated the "open ports" leg of the lethal trifecta. Combined with secrets management from Module 6, that's two down, one to go (monitoring, Module 10).

---

## Try This (Optional Experiments)

**Experiment 1: Watch the tunnel reconnect.** Run `docker compose restart cloudflared` and watch the logs. Notice how it re-establishes all four connections within seconds? That's the redundancy at work.

**Experiment 2: Check the Cloudflare dashboard.** After running your `curl` test, go to the Cloudflare dashboard --> **Analytics & Logs** --> **Traffic**. You should see your test request logged there. Cloudflare gives you traffic analytics for free.

**Experiment 3: Test the catch-all.** Try curling a subdomain you haven't configured:

```bash
curl -I https://doesnotexist.yourdomain.com
```

You should get a 502 or connection error. Cloudflare doesn't route traffic that doesn't match a tunnel hostname. Anything unexpected gets rejected.

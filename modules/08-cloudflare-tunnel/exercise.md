# Exercise: Setting Up Cloudflare Tunnel

## What We're Doing

You're going to create a Cloudflare Tunnel that routes traffic to your VPS without opening a single inbound port. By the end, you'll have a working tunnel with public URLs for your services, and you'll prove your server is invisible by scanning it.

## Prerequisites

- Your VPS is running with OpenClaw natively and Docker for support services
- UFW is configured to deny all inbound except SSH (Module 7)
- Secrets management is set up (Module 7)
- A credit/debit card for domain purchase (~$10/year) -- or an existing domain
- A web browser for the Cloudflare dashboard
- About 30 minutes

---

## Step 1: Create a Cloudflare Account

Head to [dash.cloudflare.com](https://dash.cloudflare.com) and sign up for a free account. Use a real email -- you'll need to verify it.

The free plan is all you need. Cloudflare will try to upsell you on paid plans -- politely decline. The free tier includes:

- Tunnel support (unlimited tunnels)
- DNS management
- DDoS protection
- TLS certificates

All free. Cloudflare's business model is selling enterprise features to big companies, so the basics are genuinely free.

---

## Step 2: Get a Domain

You need a domain for the tunnel to route through.

**Option A: Buy from Cloudflare (recommended).** In the dashboard, click **Domain Registration** > **Register Domain**. Search for something short and cheap -- `.com` domains run about $10/year. Cloudflare sells at cost with no markup.

**Option B: Transfer an existing domain.** Click **Add a Site** on the dashboard. Cloudflare will give you two nameservers to set at your current registrar. Propagation takes a few minutes to a few hours.

Whichever path you choose, your domain must be active in Cloudflare before continuing.

> **Pro tip:** Pick a domain you're okay using long-term. Your service URLs will be tied to it, and changing later means updating bookmarks and configurations.

---

## Step 3: Create the Tunnel

Now the fun part.

1. In the Cloudflare dashboard, go to **Zero Trust** (left sidebar -- might be labeled "Cloudflare One" or have a shield icon)
2. Navigate to **Networks** > **Tunnels**
3. Click **Create a tunnel**
4. Select **Cloudflared** as the connector type
5. Name your tunnel something descriptive -- `openclaw-vps` works great
6. Click **Save tunnel**

Cloudflare will show installation instructions for various platforms. Look for the **Docker** option.

You'll see a command like:

```bash
docker run cloudflare/cloudflared:latest tunnel --no-autoupdate run --token eyJhIjoiNzA2...very-long-string
```

**Don't run this command.** We're putting this in Docker Compose. But copy the token -- that long string after `--token`. You'll need it in Step 5.

The token starts with `eyJ` and is usually 150+ characters. Copy the whole thing.

---

## Step 4: Store the Tunnel Token as a Docker Secret

SSH into your VPS. The tunnel token is a secret -- treat it like one.

```bash
cd ~/openclaw-deploy
echo -n "eyJhIjoiNzA2...your-actual-token" > secrets/cloudflare_tunnel_token
chmod 600 secrets/cloudflare_tunnel_token
```

Verify:

```bash
ls -la secrets/cloudflare_tunnel_token
```

Should show `-rw-------`.

---

## Step 5: Add Public Hostname Routes

Back in the Cloudflare dashboard, click on your tunnel and go to the **Public Hostname** tab. Add your first route:

| Field | Value |
|---|---|
| **Subdomain** | `status` (or whatever you prefer) |
| **Domain** | Select your domain from the dropdown |
| **Service Type** | `HTTP` |
| **URL** | `uptime-kuma:3001` |

This tells Cloudflare: "When someone requests `status.yourdomain.com`, forward the traffic through the tunnel to port 3001 of the Docker container named `uptime-kuma`."

Notice the URL is `uptime-kuma:3001` -- that's the Docker container name. Because `cloudflared` runs on the same Docker network as Uptime Kuma, it resolves the container name directly.

Now add a second route for OpenClaw:

| Field | Value |
|---|---|
| **Subdomain** | `openclaw` (or whatever you prefer) |
| **Domain** | Select your domain from the dropdown |
| **Service Type** | `HTTP` |
| **URL** | `localhost:18789` |

This one is different -- notice the URL is `localhost:18789`, not a container name. That's because **OpenClaw runs natively on the VPS**, not in Docker. The `cloudflared` container can reach the host's `localhost` to connect to the native OpenClaw gateway.

> **Pro tip:** If `localhost:18789` doesn't work, try `host.docker.internal:18789` or your VPS's actual private IP address. Some Docker setups need an explicit host reference.

Click **Save hostname** for each route.

---

## Step 6: Add cloudflared to Docker Compose

On your VPS, update your `docker-compose.yml` to include the `cloudflared` service.

You can use the snippet from `starter/tunnel-compose-snippet.yml`:

```yaml
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
```

And in the top-level `secrets:` section, add:

```yaml
secrets:
  cloudflare_tunnel_token:
    file: ./secrets/cloudflare_tunnel_token
  # ... your other secrets
```

A few things to notice:

- **No port mappings.** This container doesn't expose any ports. The whole point is outbound-only.
- **`restart: unless-stopped`** -- if the tunnel crashes, Docker restarts it.
- **`networks: openclaw-net`** -- same network as your other Docker support services, so it can reach them by container name.
- **The token is read from a secret file**, not passed as an environment variable.

---

## Step 7: Push Via GitHub Actions

If you've been deploying via GitHub Actions (Module 6), update your repository and push:

```bash
# On your local machine
git add docker-compose.yml
git commit -m "Add cloudflared tunnel service"
git push
```

GitHub Actions will deploy the updated compose file to your VPS.

If you're deploying manually, SSH into the VPS and run:

```bash
cd ~/openclaw-deploy
docker compose up -d cloudflared
```

---

## Step 8: Verify the Tunnel is Running

Check the logs:

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

Four connections registered means the tunnel is healthy. Cloudflare establishes multiple connections for redundancy -- if one drops, traffic routes through the others.

If you see errors about invalid tokens, double-check that you copied the entire token string and that the secret file has no trailing newline.

Back in the Cloudflare dashboard, go to **Zero Trust** > **Networks** > **Tunnels**. Your tunnel should show as **HEALTHY** with a green indicator.

---

## Step 9: Test the Tunnel

From your *local machine* (not the VPS), test the routes:

```bash
# Test the monitoring route (expect 502 if Uptime Kuma isn't running yet)
curl -I https://status.yourdomain.com

# Test the OpenClaw route (should get a response from the native gateway)
curl -I https://openclaw.yourdomain.com
```

You'll likely get a `502` for the monitoring route right now because Uptime Kuma isn't running yet -- that's fine! The important thing is that you *got an HTTP response*. That means:

1. DNS is routing correctly through Cloudflare
2. The tunnel is forwarding traffic to your VPS
3. Cloudflare is handling TLS (notice you used `https://` and it just worked -- no certificate setup)

For the OpenClaw route, you should get a response from the native gateway on port 18789.

If you get a connection timeout or DNS error, wait a few minutes -- DNS propagation can take up to 5 minutes for new routes.

---

## Step 10: Prove Your Server Is Invisible

This is the satisfying part.

From your local machine, check what's visible on your VPS:

```bash
# If you have nmap installed:
nmap -Pn YOUR_VPS_IP
```

Or use an online port scanner like [YouGetSignal](https://www.yougetsignal.com/tools/open-ports/). Check ports 80, 443, 3001, 18789.

**What do you expect to see?**

If everything is configured correctly:
- Port 80: Closed/Filtered
- Port 443: Closed/Filtered
- Port 3001: Closed/Filtered (Docker bound to 127.0.0.1)
- Port 18789: Closed/Filtered (native OpenClaw, blocked by UFW)
- Port 22: Open (SSH) or Filtered (depending on your UFW config)

Your VPS is a ghost. The monitoring dashboard will be accessible through `https://status.yourdomain.com` (once we set up Uptime Kuma in Module 9), and OpenClaw is reachable through `https://openclaw.yourdomain.com`, but port scanners see nothing. Your server is invisible to the internet while still being fully functional.

---

## Step 11: Close Non-SSH Ports (Optional but Recommended)

If you're feeling confident, you can go even further. Check if you have any UFW rules beyond SSH:

```bash
sudo ufw status numbered
```

If you see rules for ports other than 22 that you don't need, delete them:

```bash
sudo ufw delete <rule_number>
```

The goal: SSH is the only open port. Everything else goes through the tunnel.

> **Feeling brave?** If your VPS provider has its own firewall settings, you can restrict SSH access to just your IP there too. If you get locked out, the provider's web console is your backup.

---

## What Just Happened?

Let's trace what you built:

1. **Cloudflare account + domain** -- gives you a DNS namespace to work with
2. **Tunnel** -- an authenticated, outbound-only connection from your VPS to Cloudflare
3. **Hostname routes** -- map subdomains to local services through the tunnel
4. **Hybrid routing** -- Docker services by container name, native OpenClaw via `localhost:18789`
5. **cloudflared container** -- runs the tunnel client on the same Docker network as your support services
6. **Zero open ports** -- verified by port scan

The connection flows outbound from your VPS. Cloudflare holds it open. When traffic arrives for your domain, Cloudflare routes it through the tunnel. Your firewall never had to open a port.

You just eliminated the "open ports" leg of the lethal trifecta. Combined with secrets management from Module 7, that's two down, one to go (monitoring, Module 9).

---

## Troubleshooting

**"Tunnel shows as INACTIVE in the dashboard"**

Check that the cloudflared container is running: `docker compose ps cloudflared`. Check logs: `docker compose logs cloudflared`. Common issue: the token file has a trailing newline (recreate with `echo -n`).

**"I get a 502 Bad Gateway for the OpenClaw route"**

This means the tunnel is working but can't reach OpenClaw. Check that OpenClaw is running natively: `openclaw gateway status`. Verify it's listening on port 18789: `sudo ss -tlnp | grep 18789`. If `localhost:18789` doesn't work in the Cloudflare route, try `host.docker.internal:18789`.

**"I get a 502 Bad Gateway for a Docker service route"**

Check that the target container is running and on the same Docker network as cloudflared. The service URL in the Cloudflare dashboard must match the container name exactly.

**"DNS doesn't resolve"**

New DNS records can take up to 5 minutes to propagate. Try `dig status.yourdomain.com` to check if the DNS record exists. If it shows a Cloudflare IP, DNS is working.

**"Token authentication failed"**

The token might be truncated. Go back to the Cloudflare dashboard, click your tunnel, and re-copy the token. Make sure you got the entire string.

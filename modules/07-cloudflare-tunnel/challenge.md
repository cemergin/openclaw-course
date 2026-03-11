# Challenge: Map All Your Routes

## The Scenario

Your tunnel is running and you've got one route configured. But OpenClaw isn't the only service you'll need to expose. Over the next few modules, you'll deploy:

- **OpenClaw** -- the AI agent (WhatsApp webhooks land here)
- **Uptime Kuma** -- a monitoring dashboard so you can check your stack's health from your phone
- **A kill switch endpoint** -- an emergency URL that stops OpenClaw instantly (Module 11)

Your job: plan out all the subdomain routes you'll need, configure them in the Cloudflare dashboard, and verify that everything routes correctly -- including confirming that anything you *didn't* configure gets properly rejected.

## Your Task

1. **Plan your routing table.** Decide on subdomains for each service. Think about what makes sense -- should the monitoring dashboard be at `status.yourdomain.com`? `monitor.yourdomain.com`? Something non-obvious for security?

2. **Configure all routes in the Cloudflare dashboard.** Add public hostname entries for:
   - OpenClaw (the main service, port 3000)
   - Uptime Kuma (monitoring, port 3001)
   - A placeholder for the kill switch path (we'll build the actual service in Module 11)

3. **Test each route.** Curl each subdomain and confirm you get a response (even if it's a 502 because the backend service isn't running yet -- that still proves the routing works).

4. **Verify the catch-all.** Confirm that unconfigured subdomains and random paths return errors, not content.

## Success Criteria

- [ ] At least 2 public hostname routes are configured in the Cloudflare dashboard
- [ ] Each route maps to the correct local service and port
- [ ] `curl -I https://your-configured-subdomain.yourdomain.com` returns an HTTP response (any status code)
- [ ] `curl -I https://unconfigured-subdomain.yourdomain.com` returns an error or no response
- [ ] Your VPS still shows zero open public ports on a port scan

---

## Hints

<details>
<summary>Hint 1: Planning your routes (direction)</summary>

Think about who needs to access each service. WhatsApp webhooks need to be at a stable URL you'll give to Meta. The monitoring dashboard is for your eyes only -- but it's convenient to access from your phone without SSH. The kill switch needs a secret path that's hard to guess.

Here's a starting point for your routing table:

| Subdomain | Service | Port | Who uses it |
|---|---|---|---|
| `openclaw` | OpenClaw | 3000 | Meta's webhook system |
| `status` | Uptime Kuma | 3001 | You, from your phone |
| (path-based) | Kill switch | 80 | You, in an emergency |

</details>

<details>
<summary>Hint 2: Configuring the routes (approach)</summary>

In the Cloudflare Zero Trust dashboard, go to your tunnel --> **Public Hostname** tab. For each route:

1. Click **Add a public hostname**
2. Set the subdomain (e.g., `status`)
3. Select your domain
4. Set the service type to `HTTP`
5. Set the URL to the container name and port (e.g., `uptime-kuma:3001`)

For path-based routing (like the kill switch), you can add a path in the public hostname configuration. Set the subdomain to `openclaw`, the path to `/killswitch/YOUR_SECRET_STRING`, and the service to `http://killswitch:80/kill`.

Remember: the container names in the URL are Docker container names, not hostnames. They must match the `container_name` in your `docker-compose.yml`.

</details>

<details>
<summary>Hint 3: Testing and verification (nearly there)</summary>

Test each route from your local machine (not the VPS):

```bash
# Should return a response (even 502 if the service isn't running)
curl -I https://openclaw.yourdomain.com
curl -I https://status.yourdomain.com

# Should NOT return a valid response
curl -I https://nope.yourdomain.com
```

For the port scan verification:

```bash
nmap -Pn your.vps.ip.address
```

You should see "All 1000 scanned ports are filtered" or only SSH (port 22). If you see port 443 or any other service port open, something is wrong with your UFW configuration -- go back to Module 5 and re-check.

</details>

---

## Solution

<details>
<summary>Click to reveal the full solution</summary>

### Routing Table

| Subdomain | Domain | Service Type | URL | Purpose |
|---|---|---|---|---|
| `openclaw` | yourdomain.com | HTTP | `openclaw:3000` | WhatsApp webhooks + API |
| `status` | yourdomain.com | HTTP | `uptime-kuma:3001` | Monitoring dashboard |

The kill switch route will be added in Module 11 when we build the kill switch container. For now, having OpenClaw and Uptime Kuma routes is sufficient.

### Adding Routes in the Dashboard

1. Go to **Zero Trust** --> **Networks** --> **Tunnels**
2. Click your tunnel name --> **Public Hostname** tab
3. For each route, click **Add a public hostname** and fill in the values from the table above

### Testing

```bash
# Test OpenClaw route (expect 502 if OpenClaw isn't running yet)
curl -I https://openclaw.yourdomain.com
# HTTP/2 502 <-- tunnel works, backend just isn't up

# Test Uptime Kuma route (expect 502 if Kuma isn't running yet)
curl -I https://status.yourdomain.com
# HTTP/2 502 <-- same, tunnel works

# Test catch-all (expect error -- no route configured)
curl -I https://fakething.yourdomain.com
# curl: (6) Could not resolve host  <-- DNS doesn't resolve for unconfigured subdomains
# OR: HTTP/2 502 if using a wildcard DNS record

# Verify zero open ports
nmap -Pn your.vps.ip.address
# All 1000 scanned ports are filtered (or only SSH visible)
```

### Why This Approach

**Separate subdomains per service** (instead of path-based routing for everything) gives you flexibility:

- You can apply different Cloudflare settings per subdomain (e.g., caching rules, access policies)
- Each service gets a clean URL that's easy to bookmark
- You can add Cloudflare Access (authentication) to specific subdomains later -- for example, requiring a login to access the monitoring dashboard, while keeping the webhook endpoint open for Meta

**The tradeoff:** Every subdomain is discoverable if someone knows your domain and tries common subdomains like `status` or `admin`. For monitoring, this is acceptable because Uptime Kuma has its own login. For the kill switch (Module 11), we use path-based routing with a secret string precisely because discoverability is a concern there.

There's no perfect answer -- it's about matching the security model to the threat model for each service.

</details>

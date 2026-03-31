# Challenge: Map All Your Routes and Lock It Down

## The Scenario

Your tunnel is running and you've got routes configured. But you'll want more -- a monitoring dashboard, a kill switch, possibly future webhook integrations. Your job: plan out all the routes you'll need, configure them, and verify that your server is truly invisible.

## Task

### Part 1: Plan Your Routing Table

1. Think about what services you'll want to expose through the tunnel. Consider:
   - **Uptime Kuma** (Module 9) -- monitoring dashboard for checking your stack's health from your phone
   - **Kill switch** (Module 9) -- emergency endpoint to stop OpenClaw instantly
   - **OpenClaw gateway** -- the native OpenClaw process for webhook integrations

2. Decide on subdomains for each. Should the monitoring be at `status.yourdomain.com`? `monitor.yourdomain.com`? Something non-obvious for a bit of extra obscurity?

3. Write out your routing table:

   | Subdomain | Service | URL | Who uses it |
   |---|---|---|---|
   | `???` | Uptime Kuma (Docker) | `uptime-kuma:3001` | You, from your phone |
   | `???` | OpenClaw (native) | `localhost:18789` | Future webhooks |
   | (path-based?) | Kill switch (Docker) | `killswitch:9090` | You, in an emergency |

### Part 2: Configure Multiple Routes

4. In the Cloudflare dashboard, add public hostname entries for at least 2 services. They don't all have to be running yet -- you'll see 502s for services that aren't up, which still proves the routing works.

5. Test each route from your local machine:

   ```bash
   curl -I https://status.yourdomain.com
   curl -I https://openclaw.yourdomain.com
   ```

   Any HTTP response (even 502) means the routing works.

### Part 3: Verify the Catch-All

6. Try curling a subdomain you *haven't* configured:

   ```bash
   curl -I https://doesnotexist.yourdomain.com
   ```

   You should get an error or no response. Unconfigured subdomains should not serve content.

### Part 4: Test from a Different Network

7. Pull out your phone, disconnect from WiFi (use mobile data), and try accessing your configured subdomains in a browser. Does it work? This proves the tunnel is accessible from any network, not just yours.

### Part 5: Full Port Scan

8. Run a final port scan from outside:

   ```bash
   nmap -Pn YOUR_VPS_IP
   ```

   Or use an online scanner. Verify that only SSH (if that) is visible.

### Part 6: Explore Cloudflare Analytics

9. After running your curl tests, check the Cloudflare dashboard: **Analytics & Logs** > **Traffic**. You should see your test requests logged there. Cloudflare gives you traffic analytics for free -- take a look at what's available.

## Success Criteria

- [ ] At least 2 public hostname routes configured in the Cloudflare dashboard
- [ ] Docker services routed by container name (e.g., `uptime-kuma:3001`)
- [ ] Native OpenClaw routed via `localhost:18789`
- [ ] `curl -I https://your-configured-subdomain.yourdomain.com` returns an HTTP response
- [ ] Unconfigured subdomains return errors or no response
- [ ] Port scan shows only SSH (or nothing) -- zero service ports visible
- [ ] Routes accessible from a different network (mobile data test)

---

## Hints

<details>
<summary>Hint 1: Planning your routes</summary>

Here's a solid starting configuration:

| Subdomain | Service | URL | Notes |
|---|---|---|---|
| `status` | Uptime Kuma (Docker) | `uptime-kuma:3001` | Monitoring dashboard -- has its own login page |
| `openclaw` | OpenClaw (native) | `localhost:18789` | For future webhook integrations |

For the kill switch (Module 9), you'll likely use a separate subdomain routed to the Docker kill switch container: `killswitch.yourdomain.com` -> `killswitch:9090`.

</details>

<details>
<summary>Hint 2: Adding routes in the dashboard</summary>

In **Zero Trust** > **Networks** > **Tunnels**, click your tunnel > **Public Hostname** tab.

For each route:
1. Click **Add a public hostname**
2. Set the subdomain
3. Select your domain
4. Set service type to `HTTP`
5. Set URL to the appropriate target:
   - Docker services: container name and port (e.g., `uptime-kuma:3001`)
   - Native OpenClaw: `localhost:18789`

</details>

<details>
<summary>Hint 3: Why different URL formats?</summary>

**Docker services** (Uptime Kuma, kill switch, cloudflared) all share a Docker network. `cloudflared` can reach them by container name because Docker's DNS resolves container names on the same network.

**Native OpenClaw** runs directly on the VPS, not in a Docker container. `cloudflared` reaches it via `localhost:18789` because Docker containers can access the host's loopback interface. This is the key difference in the hybrid approach.

</details>

---

## Solution

<details>
<summary>Click to reveal the full solution</summary>

### Routing Table

| Subdomain | Domain | Service Type | URL | Purpose |
|---|---|---|---|---|
| `status` | yourdomain.com | HTTP | `uptime-kuma:3001` | Monitoring dashboard (Docker) |
| `openclaw` | yourdomain.com | HTTP | `localhost:18789` | OpenClaw gateway (native) |

### Testing

```bash
# Test monitoring route (expect 502 if Uptime Kuma isn't running yet)
curl -I https://status.yourdomain.com
# HTTP/2 502 <-- tunnel works, backend just isn't up yet

# Test OpenClaw route (should work if native OpenClaw is running)
curl -I https://openclaw.yourdomain.com
# HTTP/2 200 or similar -- native gateway is responding through the tunnel

# Test catch-all
curl -I https://fakething.yourdomain.com
# Either DNS doesn't resolve, or Cloudflare returns an error

# Verify zero open ports
nmap -Pn YOUR_VPS_IP
# Expected: All 1000 scanned ports are filtered (or only SSH visible)
```

### Why This Works

The tunnel is outbound-only. Your server initiated the connection to Cloudflare. Cloudflare routes traffic through that existing connection. Your firewall never opened a port.

Port scanners see nothing because there's nothing to see. Docker support services are bound to `127.0.0.1` or not exposed at all. Native OpenClaw is blocked by UFW. The only path to reach any service is through the Cloudflare Tunnel, which means through Cloudflare's network, which means free TLS, free DDoS protection, and zero attack surface on your VPS.

</details>

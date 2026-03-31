# Zero Open Ports -- Cloudflare Tunnel

## The Elegant Solution to an Ugly Problem

Pop quiz: how do you access a monitoring dashboard on your VPS from your phone?

If you're thinking "well, I open port 3001, set up TLS, configure a reverse proxy, add authentication, and hope nobody finds my IP before I've hardened everything..." -- congratulations, you've just described the traditional approach. It works. It's also a headache, and every open port is a door that attackers will find.

What if the door just... didn't exist?

---

## The Problem with Open Ports

In Module 7, we talked about the lethal trifecta -- open ports, exposed secrets, no monitoring. We set up UFW and locked down secrets. But there's a catch: you might *need* to reach some services from outside your server. A monitoring dashboard you can check from your phone. A kill switch you can trigger from anywhere. Maybe a webhook endpoint for future integrations.

Traditionally, that means opening a port.

Here's what the traditional setup looks like:

```
You want to check monitoring from your phone
  --> You type https://your-server-ip:3001 in a browser
    --> Port 3001 must be open to the internet
      --> Everyone else can also reach port 3001
        --> Bots start probing within minutes
```

To make this work, you need port 3001 open, TLS certificates, a reverse proxy, authentication, rate limiting -- the list goes on.

And even if you do all of this perfectly, your server is still *visible*. Port scanners like Shodan and Censys catalog every open port on the internet 24/7. The moment you open port 3001, your server shows up in their databases.

This is the "open ports" leg of the lethal trifecta, and it's the hardest one to solve with traditional tools.

---

## The Cloudflare Tunnel Trick

What if instead of opening a port and *waiting* for connections, your server *reached out* to Cloudflare first? What if the connection was initiated from the inside?

That's exactly what Cloudflare Tunnel does:

```
Traditional (INBOUND -- bad):

Internet --> [Port 3001 OPEN] --> Your Server
             ^
             Anyone can knock on this door.

Cloudflare Tunnel (OUTBOUND -- good):

Your Server --> [Outbound connection] --> Cloudflare Edge
                                          ^
                                          Your server called THEM.
                                          No ports open on your end.
```

Here's the full flow when you check your monitoring dashboard:

```
You open https://status.yourdomain.com on your phone
  --> Your phone talks to Cloudflare's network
    --> Cloudflare routes it through the tunnel
      --> cloudflared on your VPS receives it
        --> cloudflared forwards to Uptime Kuma on localhost:3001
          --> You see your monitoring dashboard
```

Notice what happened? Your phone never talks to your server directly. It talks to *Cloudflare*, and Cloudflare talks to your server through a connection that *your server initiated*. Your firewall stays locked. Your ports stay closed. Your server is invisible.

Let me use an analogy. Imagine your server is a house.

**Traditional approach:** You leave your front door open with a sign that says "monitoring dashboard this way." Anyone can walk up -- you, sure, but also every bot on the internet.

**Cloudflare Tunnel:** You build a private underground passage to a secure post office. You check your dashboard through the post office. Your front door is locked, your windows are shuttered, and nobody on the street even knows your house exists.

That's not a marginal improvement. That's a fundamentally different security posture.

---

## How It Works Under the Hood

When you run `cloudflared` (the tunnel client) on your VPS, it does the following:

1. **Authenticates** with Cloudflare using a tunnel token
2. **Establishes persistent outbound connections** to Cloudflare's nearest edge servers (multiple connections for redundancy)
3. **Holds those connections open** using HTTP/2 or QUIC
4. **Waits for traffic** -- when Cloudflare receives a request for your domain, it routes it through the existing tunnel connection
5. **Forwards the request** to whatever local service you've configured (e.g., `http://localhost:18789` for OpenClaw or `http://uptime-kuma:3001` for monitoring)

The key insight: your server makes the outbound connection. Your firewall allows outbound traffic by default (that's how your server reaches the internet at all). No inbound ports needed. No firewall exceptions. Nothing.

> **Pro tip:** Because the connection is outbound, it even works behind NATs, corporate firewalls, and restrictive networks. If your server can reach the internet at all, the tunnel works.

---

## DNS Routing: One Tunnel, Many Services

A single tunnel can route traffic to *multiple* services based on the subdomain. You set up routing rules in the Cloudflare dashboard, and each subdomain points to a different service on your VPS.

Think of it like a switchboard:

```
status.yourdomain.com     -->  http://uptime-kuma:3001     (Monitoring dashboard -- Docker container)
openclaw.yourdomain.com   -->  http://localhost:18789       (OpenClaw gateway -- native process)
```

Notice the difference in URLs. This is the hybrid approach in action:

- **Docker services** (like Uptime Kuma) are reached by container name -- `uptime-kuma:3001` -- because `cloudflared` runs on the same Docker network.
- **Native OpenClaw** is reached via `localhost:18789` because it runs directly on the VPS, not in a Docker container. `cloudflared` can reach localhost because Docker containers can access the host's loopback interface.

And later, when you build the kill switch in Module 9:

```
killswitch.yourdomain.com  -->  http://killswitch:9090     (Kill switch -- Docker container)
```

You can add as many routes as you need. Future webhook integrations? Just add another route. All through the same tunnel. One `cloudflared` container. Zero open ports.

---

## The Token Method (And Why We Use It)

There are two ways to configure a Cloudflare Tunnel:

1. **Config file method** -- you write a `config.yml` and manage the tunnel from the command line
2. **Token method (dashboard)** -- you create the tunnel in Cloudflare's web dashboard, get a token, and the tunnel pulls its configuration from the cloud

We're using the token method because:

- **It's simpler for Docker.** One token and you're done. No config files to mount.
- **Route changes are instant.** Want to add a new subdomain? Change it in the dashboard. No need to SSH into your server, edit a file, and restart the container.
- **It's the recommended approach** for most use cases.

The token is a long base64-encoded string that contains your tunnel ID and authentication credentials. It's a secret -- treat it like one. We'll store it as a Docker secret, just like we did with the tunnel token in Module 7.

---

## Docker Networking: How cloudflared Reaches Your Services

This is where the hybrid approach gets interesting. `cloudflared` runs in Docker, but it needs to reach both Docker containers and native processes:

```yaml
services:
  cloudflared:
    networks:
      - openclaw-net

  uptime-kuma:
    networks:
      - openclaw-net

networks:
  openclaw-net:
```

For **Docker services** (Uptime Kuma, kill switch), `cloudflared` reaches them by container name on the shared Docker network:
- `http://uptime-kuma:3001`
- `http://killswitch:9090`

For **native OpenClaw**, `cloudflared` reaches it via `localhost` or the host's IP:
- `http://localhost:18789` (using Docker's host networking access)

In the Cloudflare dashboard route configuration, you'll use `localhost:18789` for the OpenClaw service URL. This works because Docker containers can access the host machine's loopback interface.

> **Note:** On some Docker setups, you may need to use `host.docker.internal:18789` instead of `localhost:18789`. If `localhost` doesn't work, try `host.docker.internal` or the host machine's actual IP address.

---

## The Catch-All: Blocking the Unexpected

What happens when someone requests a subdomain you haven't configured?

By default, Cloudflare Tunnel returns an error for any hostname that doesn't match a configured route. This is good -- if someone discovers your domain and pokes around at `random.yourdomain.com`, they get nothing.

You should verify that your tunnel's catch-all behavior rejects unmatched routes. Defense in depth -- even if someone knows your domain, they can only reach the specific services you've explicitly exposed.

---

## Why This Is the Biggest Security Win

After this module, your server's security posture looks like this:

| Attack Vector | Status |
|---|---|
| Port scanning (nmap, Shodan, Censys) | **Nothing to find.** Zero open ports (or just SSH). |
| Direct connection to your IP | **Blocked.** UFW denies all inbound except SSH. |
| DDoS attacks | **Cloudflare absorbs them.** They handle billions of requests daily. |
| TLS certificate management | **Cloudflare handles it.** No Let's Encrypt, no renewals, no nginx. |
| Monitoring dashboard access | **Through the tunnel.** Secure, authenticated, zero ports. |

You get free TLS, free DDoS protection, and complete invisibility from port scanners. And you didn't install nginx. You didn't wrestle with certbot. You didn't open a single port.

Combined with secrets management from Module 7 and the monitoring we'll set up in Module 9, the trifecta collapses. That's the whole point of this course's security arc.

---

## What You Need Before the Exercise

To set up Cloudflare Tunnel, you'll need:

1. **A Cloudflare account** (free tier is fine)
2. **A domain name** -- you can buy one through Cloudflare for about $10/year, or transfer an existing one
3. **Your VPS running with OpenClaw natively and Docker for support services** -- from earlier modules
4. **UFW configured** -- from Module 7

If you don't have a domain yet, don't worry -- we'll walk through getting one in the exercise. Cloudflare sells domains at cost (no markup), making them one of the cheapest registrars.

---

## What We Just Covered

- **Traditional port exposure** makes your server visible to the internet and requires TLS, reverse proxies, and authentication
- **Cloudflare Tunnel** flips the model: your server connects *out* to Cloudflare, so no inbound ports are needed
- **One tunnel** can route multiple subdomains to different local services via DNS routing
- **Hybrid routing** -- Docker services reached by container name, native OpenClaw reached via `localhost:18789`
- **The token method** is the simplest approach for Docker -- managed from the dashboard
- **Docker networking** lets cloudflared reach other Docker services by container name, and native services via localhost
- **Catch-all rules** reject traffic for any route you haven't explicitly configured
- **Combined with UFW and secrets management**, your server is invisible, your secrets are locked down, and your services are only reachable through the tunnel

Time to set it up. Head to the [exercise](exercise.md).

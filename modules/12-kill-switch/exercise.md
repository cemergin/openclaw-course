# Exercise 11: Building Your Kill Switch Arsenal

## What We're Doing

We're building all four kill switch levels, testing each one, and bookmarking the primary one on your phone. By the end, you'll have a tested escalation playbook and the muscle memory to shut down your agent in seconds.

## Prerequisites

- Your full OpenClaw stack running via Docker Compose (from Module 9)
- Cloudflare Tunnel configured and routing traffic (from Module 7)
- Uptime Kuma monitoring your services (from Module 10)
- Your phone nearby (for bookmark and app testing)
- SSH access to your VPS

## Part 1: Build the Secret URL Kill Switch

**1. Generate your kill secret**

SSH into your server and generate a random secret:

```bash
ssh openclaw@<your-server-ip>
cd ~/openclaw-stack
echo "kill-$(openssl rand -hex 12)"
```

Copy the output somewhere safe -- you'll need it in the next steps. This is your kill secret. Treat it like a password.

**2. Create the kill script**

A starter file is provided at `starter/kill.sh`. Copy it to your server and fill in the pieces, or create it directly:

```bash
mkdir -p ~/openclaw-stack/config/killswitch
nano ~/openclaw-stack/config/killswitch/kill.sh
```

The script needs to:
- Stop the openclaw container via Docker
- Log the timestamp of the kill

Make it executable:

```bash
chmod +x ~/openclaw-stack/config/killswitch/kill.sh
```

**3. Add the killswitch service to your compose file**

Open your `docker-compose.yml` and add a killswitch service. It needs:

- A minimal image (Alpine with a shell HTTP server, or use `hashicorp/http-echo` as a base -- but the simplest approach is an Alpine container running a tiny HTTP listener)
- The Docker socket mounted (`/var/run/docker.sock`)
- Your kill script mounted
- Connected to the same network the tunnel can reach
- A port binding on `127.0.0.1` for the tunnel to route to

Here's the service definition to add:

```yaml
  killswitch:
    image: alpine:latest
    container_name: killswitch
    restart: unless-stopped
    command: >
      sh -c '
      KILL_SECRET="${KILL_SECRET}"
      while true; do
        echo -e "HTTP/1.1 200 OK\r\n\r\nDone" |
        nc -l -p 9090 -q 1 > /tmp/request.txt 2>&1
        if grep -q "$${KILL_SECRET}" /tmp/request.txt; then
          sh /killswitch/kill.sh
        fi
      done
      '
    environment:
      - KILL_SECRET=<your-kill-secret-here>
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./config/killswitch/kill.sh:/killswitch/kill.sh:ro
    ports:
      - "127.0.0.1:9090:9090"
    networks:
      - internal
```

Replace `<your-kill-secret-here>` with the secret you generated in step 1.

> **Pro tip:** Yes, this is a janky HTTP server built from `nc` (netcat) in a while loop. That's intentional. A kill switch should have minimal dependencies. No web framework, no runtime, no package manager. Just Alpine, netcat, and your script. The less code, the less that can break.

**4. Add the Cloudflare Tunnel route**

In your Cloudflare dashboard, add a new public hostname rule for your tunnel:

- **Subdomain:** `openclaw` (or whatever you're already using)
- **Path:** `killswitch/*`
- **Service:** `http://killswitch:9090`

This routes `https://openclaw.yourdomain.com/killswitch/*` to your kill switch container.

**5. Bring up the new service**

```bash
cd ~/openclaw-stack
docker compose up -d killswitch
```

Verify it's running:

```bash
docker compose ps killswitch
```

**6. Test it from the server first**

Before testing from your phone, make sure it works locally:

```bash
curl http://127.0.0.1:9090/killswitch/<your-kill-secret>
```

**Before you hit enter:** What do you think will happen to the OpenClaw container?

Check if OpenClaw stopped:

```bash
docker compose ps openclaw
```

It should show as stopped or exited. You just killed it on purpose. Well done.

**7. Revive OpenClaw**

```bash
docker compose up -d openclaw
docker compose logs -f openclaw
```

Wait until you see healthy startup logs, then press `Ctrl+C`.

**8. Test from your phone**

Open your phone's browser and navigate to:

```
https://openclaw.yourdomain.com/killswitch/<your-kill-secret>
```

Check from your SSH session that OpenClaw stopped. If it did, bookmark that URL on your phone. Put it on your home screen if your OS supports it.

Revive again:

```bash
docker compose up -d openclaw
```

## Part 2: Test the WhatsApp Kill Phrase

**9. Configure the kill phrase in OpenClaw**

If OpenClaw supports a kill phrase configuration, add it to your OpenClaw config:

```yaml
kill_phrase: "EMERGENCY STOP NOW"
kill_action: shutdown
```

The exact location depends on your OpenClaw version -- check `config/openclaw/` for the main configuration file.

**10. Test it**

Send the exact message `EMERGENCY STOP NOW` to your bot via WhatsApp.

Check from SSH:

```bash
docker compose ps openclaw
```

If it stopped, the kill phrase works. Revive:

```bash
docker compose restart openclaw
```

## Part 3: Save the SSH One-Liner

**11. Test the SSH kill from your phone (optional) or a second terminal**

```bash
ssh openclaw@<your-vps-ip> "cd ~/openclaw-stack && docker compose stop openclaw"
```

Verify and revive:

```bash
ssh openclaw@<your-vps-ip> "cd ~/openclaw-stack && docker compose up -d openclaw"
```

If you have a terminal app on your phone (Termius, Blink, Prompt), save this as a snippet or shortcut.

## Part 4: Install the VPS Provider App

**12. Install your provider's mobile app**

- **AWS Lightsail:** Search "AWS Console" in your app store, install, sign in, navigate to Lightsail
- **Hetzner:** Search "Hetzner Cloud" in your app store
- **DigitalOcean:** Search "DigitalOcean" in your app store

Sign in and verify you can see your instance. Locate the power off / stop button but *do not press it yet* -- we'll save that for the challenge.

## Part 5: Save Your Escalation Playbook

**13. Fill in your escalation playbook**

A starter template is provided at `starter/escalation-playbook.md`. Fill in your specific URLs, IPs, and secrets. Keep a copy:

- On your phone (notes app or saved file)
- Printed next to your desk (yes, really -- phones die)
- In your password manager

## What Just Happened?

You built four independent methods to stop your AI agent:

- **Level 1:** A secret URL that stops OpenClaw via Docker socket, bookmarked on your phone
- **Level 2:** A WhatsApp kill phrase that short-circuits the AI pipeline
- **Level 3:** An SSH one-liner you can run from any terminal
- **Level 4:** Your VPS provider's mobile app as the nuclear option

Each method uses a different channel (HTTPS, WhatsApp, SSH, provider API), so if one is down, the others still work. You also tested the revive process for each -- because a kill switch you can't undo is just a brick-making machine.

## Try This (Optional Experiments)

- **Time yourself:** How fast can you go from "something's wrong" to "OpenClaw is stopped" using each method? The bookmark URL should be under 5 seconds. Can you beat that?
- **Test Uptime Kuma detection:** After triggering a kill, check how long it takes Uptime Kuma to notice and alert you. This tells you your monitoring's response time.
- **Wrong secret test:** Hit the kill URL with an incorrect secret. Verify you get a generic response and OpenClaw keeps running. Security matters even for your kill switch.

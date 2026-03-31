# Exercise 9: Building Your Monitoring Stack and Kill Switch

## What We're Doing

We're setting up Uptime Kuma for monitoring with Telegram alerts, then building a kill switch you can trigger from your phone. By the end, you'll know within 60 seconds when something breaks -- and you'll be able to stop your agent with a single tap.

## Prerequisites

- Native OpenClaw running on your VPS (from Module 5+)
- Docker support services running (cloudflared from Module 8)
- SSH access to your VPS as the `openclaw` user
- Your Cloudflare Tunnel working with subdomains configured
- Your Telegram bot from Module 0 (you'll reuse it for alerts)
- Your phone nearby (for bookmarking and testing)

---

## Part 1: Monitoring

### Step 1: Add Uptime Kuma to Your Docker Compose

**1. SSH into your VPS and open your compose file**

```bash
ssh openclaw@<your-server-ip>
cd ~/openclaw-deploy
nano docker-compose.yml
```

**2. Add the Uptime Kuma service**

Add this to your `services:` section:

```yaml
  uptime-kuma:
    image: louislam/uptime-kuma:1
    container_name: uptime-kuma
    restart: unless-stopped
    volumes:
      - uptime-kuma-data:/app/data
    ports:
      - "127.0.0.1:3001:3001"
    networks:
      - openclaw-net
```

And add the volume to your `volumes:` section at the bottom:

```yaml
volumes:
  # ... your existing volumes ...
  uptime-kuma-data:
```

The `127.0.0.1:3001:3001` binding means Uptime Kuma is only accessible from localhost -- not from the internet. Docker bypasses UFW, but the `127.0.0.1:` prefix keeps it local. The Cloudflare Tunnel will handle external access.

**3. Create the health check script**

Before we deploy, let's also create a health check script. A starter template is provided in this module's `starter/healthcheck.sh`. Copy it to your server or create it directly:

```bash
nano /home/openclaw/healthcheck.sh
```

Use the starter template as your base (the one with TODO comments). Fill in the missing pieces:

- Set thresholds for CPU, memory, and disk (start with 80% for CPU/disk, 85% for memory on a 1GB instance)
- Add the commands to read current CPU, memory, and disk usage
- Add the service check for native OpenClaw using `openclaw gateway status`
- Add the container check for cloudflared
- Add the logging line at the bottom

If you get stuck, the completed version is in `solution/healthcheck.sh`.

**4. Make the health check executable**

```bash
chmod +x /home/openclaw/healthcheck.sh
```

**5. Test the health check locally**

```bash
/home/openclaw/healthcheck.sh
```

You should see something like:

```
Wed Mar 30 14:30:00 UTC 2026: CPU=3% MEM=62% DISK=41% -- OK
```

### Step 2: Route Uptime Kuma via Cloudflare Tunnel

**6. Add a tunnel route for the monitoring dashboard**

In your Cloudflare Zero Trust dashboard, add a new public hostname for your tunnel:

- **Subdomain:** `monitor`
- **Domain:** `yourdomain.com`
- **Service:** `http://uptime-kuma:3001`

This works because cloudflared and Uptime Kuma are on the same Docker network.

### Step 3: Deploy

**7. Deploy your changes**

```bash
cd ~/openclaw-deploy
docker compose pull
docker compose up -d
```

**8. Verify everything is running**

```bash
docker compose ps
```

You should see `uptime-kuma` in the list with status "Up."

Also verify native OpenClaw is still running:

```bash
openclaw gateway status
```

### Step 4: Configure Uptime Kuma Dashboard

**9. Access the dashboard**

Open your browser and go to `https://monitor.yourdomain.com`.

First time? Uptime Kuma will ask you to create an admin account. Pick a strong password -- this dashboard is exposed to the internet through your tunnel.

**10. Add an HTTP monitor for OpenClaw**

Click "Add New Monitor" and configure:

- **Monitor Type:** HTTP(s)
- **Friendly Name:** OpenClaw
- **URL:** `http://localhost:18789/health`
- **Heartbeat Interval:** 60 seconds
- **Retries:** 3
- **Retry Interval:** 30 seconds

The URL uses `localhost:18789` because OpenClaw runs natively on the VPS, not in a Docker container. Uptime Kuma's Docker container can reach the host's localhost.

> **Note:** If `localhost` doesn't work from inside the Uptime Kuma container, try `host.docker.internal:18789` or your VPS's actual private IP address.

Click "Save" and watch it start checking. You should see green heartbeats appearing.

### Step 5: Set Up Telegram Notifications

**11. Connect your existing Telegram bot**

Go to **Settings > Notifications** in Uptime Kuma (or click the bell icon on your monitor). Click "Setup Notification" and choose **Telegram**.

- **Bot Token:** Use the same bot token from Module 0 (the one you used for OpenClaw itself)
- **Chat ID:** Your personal chat ID. If you don't remember it, send a message to `@userinfobot` on Telegram and it'll tell you.

Click "Test" to verify. You should get a test message from your bot on Telegram.

**12. Enable the notification on your OpenClaw monitor**

Go back to your OpenClaw monitor, click "Edit," and under "Notifications," toggle on the Telegram notification you just created.

Now when OpenClaw goes down, your phone will buzz.

### Step 6: Test the Full Alert Pipeline

**13. Break something on purpose**

This is the fun part. Stop OpenClaw and see if your monitoring catches it:

```bash
openclaw gateway stop
```

Now watch Uptime Kuma. Within 60-90 seconds (one check interval plus retries), you should:
- See the monitor turn red in the dashboard
- Receive a Telegram notification on your phone

**This is the moment.** If your phone buzzes with an alert, your monitoring stack works.

**14. Restart OpenClaw**

```bash
openclaw gateway start
```

Uptime Kuma should turn green again, and you'll get a "recovered" notification on Telegram.

---

## Part 2: Kill Switch

### Step 7: Generate Your Kill Secret

**15. Generate random secrets for kill and revive**

```bash
echo "kill-$(openssl rand -hex 12)"
echo "revive-$(openssl rand -hex 12)"
```

Copy both outputs somewhere safe. These are your kill and revive secrets.

### Step 8: Create the Kill Script

**16. Create the kill and revive scripts**

A starter template is provided at `starter/kill.sh`. Copy it to your server and fill in the pieces, or create the scripts directly:

```bash
mkdir -p ~/openclaw-deploy/config/killswitch
nano ~/openclaw-deploy/config/killswitch/kill.sh
```

The kill script should:
- Stop native OpenClaw via `openclaw gateway stop`
- Log the timestamp of the kill

Create the revive script too:

```bash
nano ~/openclaw-deploy/config/killswitch/revive.sh
```

The revive script should:
- Start native OpenClaw via `openclaw gateway start`
- Log the timestamp of the revive

Make both executable:

```bash
chmod +x ~/openclaw-deploy/config/killswitch/kill.sh
chmod +x ~/openclaw-deploy/config/killswitch/revive.sh
```

If you get stuck, the completed versions are in `solution/kill.sh`.

### Step 9: Add the Kill Switch Service to Docker Compose

**17. Add the killswitch service to your compose file**

```bash
nano ~/openclaw-deploy/docker-compose.yml
```

Add this service:

```yaml
  killswitch:
    image: alpine:latest
    container_name: killswitch
    restart: unless-stopped
    command: >
      sh -c '
      KILL_SECRET="${KILL_SECRET}"
      REVIVE_SECRET="${REVIVE_SECRET}"
      while true; do
        echo -e "HTTP/1.1 200 OK\r\n\r\nDone" |
        nc -l -p 9090 -q 1 > /tmp/request.txt 2>&1
        if grep -q "$$KILL_SECRET" /tmp/request.txt; then
          sh /killswitch/kill.sh
        elif grep -q "$$REVIVE_SECRET" /tmp/request.txt; then
          sh /killswitch/revive.sh
        fi
      done
      '
    environment:
      - KILL_SECRET=<your-kill-secret-here>
      - REVIVE_SECRET=<your-revive-secret-here>
    volumes:
      - ./config/killswitch/kill.sh:/killswitch/kill.sh:ro
      - ./config/killswitch/revive.sh:/killswitch/revive.sh:ro
      - /usr/local/bin/openclaw:/usr/local/bin/openclaw:ro
      - /home/openclaw/openclaw-deploy:/home/openclaw/openclaw-deploy:ro
    ports:
      - "127.0.0.1:9090:9090"
    networks:
      - openclaw-net
```

Replace `<your-kill-secret-here>` and `<your-revive-secret-here>` with the secrets you generated in step 15.

Key things to notice:
- The `openclaw` binary is mounted into the container so the kill script can call `openclaw gateway stop/start`
- The OpenClaw deploy directory is mounted so the CLI can find its configuration
- Port 9090 is bound to `127.0.0.1` -- Docker bypasses UFW, so this prefix is critical

> **Yes, this is a janky HTTP server built from `nc` (netcat) in a while loop.** That's intentional. A kill switch should have minimal dependencies. No web framework, no runtime, no package manager. Just Alpine, netcat, and your script. The less code, the less that can break.

### Step 10: Route the Kill Switch via Cloudflare Tunnel

**18. Add a tunnel route for the kill switch**

In your Cloudflare Zero Trust dashboard, add another public hostname:

- **Subdomain:** `killswitch`
- **Domain:** `yourdomain.com`
- **Service:** `http://killswitch:9090`

### Step 11: Deploy the Kill Switch

**19. Deploy**

```bash
cd ~/openclaw-deploy
docker compose up -d killswitch
```

**20. Verify it's running**

```bash
docker compose ps killswitch
```

### Step 12: Test Kill and Revive

**21. Test from the server first**

Before testing from your phone, make sure it works locally:

```bash
curl http://127.0.0.1:9090/<your-kill-secret>
```

**Before you hit enter:** What do you think will happen to OpenClaw?

Check if OpenClaw stopped:

```bash
openclaw gateway status
```

It should show as stopped. You just killed it on purpose.

**22. Revive it**

```bash
curl http://127.0.0.1:9090/<your-revive-secret>
```

Check that OpenClaw is back:

```bash
openclaw gateway status
```

**23. Test from your phone**

Open your phone's browser and navigate to:

```
https://killswitch.yourdomain.com/<your-kill-secret>
```

Check from your SSH session that OpenClaw stopped. Then navigate to:

```
https://killswitch.yourdomain.com/<your-revive-secret>
```

Verify OpenClaw restarted.

**24. Bookmark both URLs on your phone**

- Bookmark the kill URL. Label it something obvious like "KILL OPENCLAW."
- Bookmark the revive URL. Label it "REVIVE OPENCLAW."
- Put them on your home screen if your phone supports it.

### Step 13: Verify Monitoring Catches the Kill

**25. Kill from your phone, watch Uptime Kuma**

Tap the kill bookmark. Then watch Uptime Kuma (at `monitor.yourdomain.com`) and your Telegram notifications.

Within 60-90 seconds:
- Uptime Kuma turns red
- Telegram buzzes with a "down" alert

Tap the revive bookmark. Within another 60-90 seconds:
- Uptime Kuma turns green
- Telegram buzzes with a "recovered" alert

If all of that happened, your monitoring and kill switch are fully integrated. The monitoring detects the kill, and the kill switch works from your phone.

### Step 14: Document Your Escalation Playbook

**26. Fill in your escalation playbook**

A starter template is provided at `starter/escalation-playbook.md`. Fill in your specific URLs, IPs, and secrets. Keep a copy:

- On your phone (notes app or saved file)
- Printed next to your desk (yes, really -- phones die)
- In your password manager

---

## What Just Happened?

You built a complete monitoring and incident response system:

**Monitoring:**
- Uptime Kuma checks native OpenClaw every 60 seconds via its health endpoint
- A health check script monitors CPU, memory, disk, and service status
- Telegram notifications alert you within 90 seconds of a failure
- The dashboard is accessible from anywhere via your Cloudflare Tunnel

**Kill Switch:**
- A secret URL runs `openclaw gateway stop` to halt your agent with a single tap from your phone
- A revive URL runs `openclaw gateway start` to bring it back without needing to SSH in
- Three escalation levels (URL, SSH, VPS app) ensure you can always pull the plug
- Uptime Kuma confirms every kill and revive with Telegram alerts

The lethal trifecta is now fully addressed. Tunnel locks the doors. Secrets hide the keys. Monitoring watches the cameras. And the kill switch is the fire alarm you can pull from anywhere.

## Try This (Optional Experiments)

- **Add a cloudflared monitor:** In Uptime Kuma, add a Docker container monitor or HTTP monitor for the tunnel service.
- **Time your alert pipeline:** Stop OpenClaw with `openclaw gateway stop`, start a timer, and measure exactly how long until you get a Telegram notification. Aim for under 2 minutes.
- **Wrong secret test:** Hit the kill URL with an incorrect secret. Verify you get a generic response and OpenClaw keeps running.
- **Set up cron:** Add the health check script to cron for automatic monitoring: `*/5 * * * * /home/openclaw/healthcheck.sh >> /var/log/openclaw-health.log 2>&1`

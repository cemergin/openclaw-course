# Exercise 10: Building Your Monitoring Stack

## What We're Doing

We're setting up three layers of monitoring: a health check script that runs every 5 minutes via cron, Uptime Kuma configured with monitors and notifications, and optionally an external dead-man's switch with Healthchecks.io.

## Prerequisites

- Your full OpenClaw stack running via Docker Compose (from Module 9)
- SSH access to your VPS as the `openclaw` user
- Your Cloudflare Tunnel working with `status.yourdomain.com` routed to Uptime Kuma
- A Telegram account, email, or Discord for receiving alerts

## Part 1: The Health Check Script

**1. SSH into your VPS and check the current state**

```bash
ssh openclaw@<your-server-ip>
cd ~/openclaw-stack
docker compose ps
```

All services should be running. Take a mental snapshot of what "healthy" looks like.

**2. Check your server's current resource usage**

```bash
echo "CPU: $(top -bn1 | grep 'Cpu(s)' | awk '{print $2}')% | MEM: $(free -h | awk '/Mem/{print $3"/"$2}') | DISK: $(df -h / | awk 'NR==2{print $3"/"$2}')"
```

**Before you run this:** What numbers do you expect? On a $5 Lightsail instance running your stack, CPU should be low (under 10% idle), memory might be 50-70% used, and disk probably 30-50%.

Write down the actual numbers. These are your baseline -- you'll use them to set sensible thresholds.

**3. Look at per-container resource usage**

```bash
docker stats --no-stream
```

Note which container uses the most memory. It'll probably be OpenClaw. This is normal.

**4. Create the health check script**

You'll find a starter template in this module's `starter/` directory. Copy it to your server, or create it directly:

```bash
nano /home/openclaw/healthcheck.sh
```

Use the starter template as your base (the one with TODO comments). Fill in the missing pieces:

- Set thresholds for CPU, memory, and disk (start with 80% for all three)
- Add the commands to read current CPU, memory, and disk usage
- Add the container check for OpenClaw
- Add the logging line at the bottom

If you get stuck, the solution is in the `solution/` directory -- but try to write it yourself first. The commands are all in the lesson.

**5. Make it executable and test it**

```bash
chmod +x /home/openclaw/healthcheck.sh
/home/openclaw/healthcheck.sh
```

You should see a line like:

```
Wed Mar 11 14:30:00 UTC 2026: CPU=3% MEM=62% DISK=41% -- OK
```

If you see warnings about thresholds, either your server is actually stressed or your thresholds are too low. Adjust as needed.

**6. Test the container-down detection**

This is the fun part. Let's intentionally break something and watch the script catch it:

```bash
cd ~/openclaw-stack
docker compose stop openclaw
```

Now run the health check:

```bash
/home/openclaw/healthcheck.sh
```

**What do you expect to see?** The script should detect that OpenClaw is down and restart it.

Verify it came back:

```bash
docker compose ps
```

OpenClaw should be running again. The health check caught the problem and fixed it automatically.

## Part 2: Automate With Cron

**7. Set up the cron job**

```bash
crontab -e
```

If prompted to choose an editor, pick nano (option 1 -- easiest).

Add this line at the bottom of the file:

```
*/5 * * * * /home/openclaw/healthcheck.sh >> /var/log/openclaw-health.log 2>&1
```

Save and exit (Ctrl+O, Enter, Ctrl+X in nano).

**8. Verify cron accepted it**

```bash
crontab -l
```

You should see your line listed. Cron is now running your health check every 5 minutes.

**9. Create the log file and set permissions**

```bash
sudo touch /var/log/openclaw-health.log
sudo chown openclaw:openclaw /var/log/openclaw-health.log
```

**10. Wait 5 minutes, then check the log**

```bash
tail -5 /var/log/openclaw-health.log
```

You should see at least one entry from the cron run. If it's empty after 5 minutes, check that the script path is correct and the script is executable.

> **Pro tip:** Can't wait 5 minutes? Run the script manually with the same redirect to verify the log works: `/home/openclaw/healthcheck.sh >> /var/log/openclaw-health.log 2>&1 && tail -3 /var/log/openclaw-health.log`

## Part 3: Configure Uptime Kuma

**11. Access Uptime Kuma**

Open your browser and go to `https://status.yourdomain.com` (the subdomain you configured in Module 7).

First time? Uptime Kuma will ask you to create an admin account. Pick a strong password -- this dashboard is exposed to the internet through your tunnel.

**12. Add an HTTP monitor for OpenClaw**

Click "Add New Monitor" and configure:

- **Monitor Type:** HTTP(s)
- **Friendly Name:** OpenClaw
- **URL:** `http://openclaw:3000/health`
- **Heartbeat Interval:** 60 seconds
- **Retries:** 3
- **Retry Interval:** 30 seconds

The URL uses `openclaw` (the Docker service name) because Uptime Kuma is on the same Docker network. It can reach OpenClaw directly without going through the tunnel or any port mapping.

Click "Save" and watch it start checking. You should see green heartbeats appearing.

**13. Set up notifications**

This is the critical part -- monitoring without alerts is a dashboard nobody checks.

Go to **Settings > Notifications** (or click the bell icon on your monitor). Click "Setup Notification" and pick your preferred channel:

**For Telegram** (recommended -- you already have it from the Speed Run):
- Bot Token: use the same bot or create a new one via @BotFather
- Chat ID: send a message to @userinfobot to get your ID
- Test the notification before saving

**For Email:**
- Use an SMTP service (Gmail app password, SendGrid free tier, etc.)
- Test delivery before relying on it

**For Discord:**
- Create a webhook in your Discord server (Server Settings > Integrations > Webhooks)
- Paste the webhook URL into Uptime Kuma

Whichever you pick, click "Test" to verify it works. You should get a test message on your device.

**14. Test the full alert pipeline**

Let's trigger a real alert. Stop OpenClaw:

```bash
cd ~/openclaw-stack
docker compose stop openclaw
```

Watch Uptime Kuma. Within 60-90 seconds (one check interval plus retries), you should:
- See the monitor turn red in the dashboard
- Receive a notification on your phone/email/Discord

This is the moment. If your phone buzzes with an alert, your monitoring stack works.

Now restart OpenClaw:

```bash
docker compose start openclaw
```

Uptime Kuma should turn green again, and you'll get a "recovered" notification.

## Part 4: External Dead-Man's Switch (Optional)

**15. Create a Healthchecks.io account**

Go to [healthchecks.io](https://healthchecks.io/) and sign up (free tier gives you 20 checks).

Create a new check:
- **Name:** OpenClaw Server
- **Period:** 5 minutes (matches your cron interval)
- **Grace Time:** 5 minutes (how long to wait after a missed ping before alerting)

Copy the ping URL. It'll look like: `https://hc-ping.com/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`

**16. Add the ping to your health check script**

Edit the script:

```bash
nano /home/openclaw/healthcheck.sh
```

Add this line at the very end of the script (replace with your actual UUID):

```bash
# External dead-man's switch -- if this stops pinging, Healthchecks.io emails you
curl -fsS -m 10 --retry 5 https://hc-ping.com/YOUR_UUID > /dev/null
```

The flags: `-f` fails silently on HTTP errors, `-sS` is silent but shows errors, `-m 10` sets a 10-second timeout, `--retry 5` retries up to 5 times.

**17. Test it**

Run the script manually:

```bash
/home/openclaw/healthcheck.sh
```

Then check the Healthchecks.io dashboard. You should see your check turn green with a "Last Ping" timestamp.

To test the alert, you'd need to stop the cron job and wait for the grace period to expire. For now, trust that it works -- the green status confirms the ping is getting through.

## What Just Happened?

You built three layers of monitoring:

1. **Health check script on cron** -- runs every 5 minutes, checks CPU/RAM/disk/services, auto-restarts OpenClaw if it crashes, logs everything to `/var/log/openclaw-health.log`
2. **Uptime Kuma** -- checks OpenClaw's health endpoint every 60 seconds, sends you push notifications when something goes down (and when it recovers)
3. **Healthchecks.io (optional)** -- external service that emails you if your server stops reporting in entirely

Each layer catches failures the others miss:
- Script catches resource issues and auto-heals crashed containers
- Uptime Kuma catches application-level failures and notifies you
- Healthchecks.io catches total server failures (when both of the above are dead)

The lethal trifecta is now fully addressed. Your server has zero open ports, your secrets are in Docker Secrets, and your monitoring will wake you up if something breaks.

## Try This (Optional Experiments)

- **Read the health log over time:** After a day, run `cat /var/log/openclaw-health.log` and see the pattern. Is resource usage consistent? Any spikes?
- **Simulate disk pressure:** Run `dd if=/dev/zero of=/tmp/bigfile bs=1M count=500` to create a 500 MB file, then run your health check to see if disk usage crosses the threshold. Clean up with `rm /tmp/bigfile`.
- **Add a second Uptime Kuma monitor:** Add one for SearXNG (`http://searxng:8080`) to monitor your search service too.
- **Check cron's own logs:** Run `grep CRON /var/log/syslog | tail -10` to see cron's execution history -- useful for debugging if your script isn't running.

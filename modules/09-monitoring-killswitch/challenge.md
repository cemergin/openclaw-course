# Challenge 9: Advanced Monitoring and the Panic Button

## The Scenario

Your monitoring and kill switch work. You can detect failures and stop your agent from your phone. But there's room to level up. What if you could see memory and CPU trends over time? What if you got a daily health digest instead of waiting for something to break? And what if things got *really* bad and you needed to kill not just OpenClaw, but everything?

## Your Mission

Complete all three challenges to build a bulletproof operational setup.

---

### Challenge 1: Memory and CPU Monitoring in Uptime Kuma

**Task:** Add resource monitoring so you can track trends, not just outages.

Right now, Uptime Kuma only checks if OpenClaw responds to HTTP requests. But your 1GB VPS could be slowly running out of memory or disk while every health check returns 200 OK. By the time OpenClaw crashes, it's too late.

**What to do:**
- Modify your health check script to push resource metrics to Uptime Kuma using a Push monitor
- Create a Push monitor in Uptime Kuma for "Server Resources"
- Add a `curl` to your health check script that pings the Push monitor URL -- but only if all resource checks pass
- If CPU, memory, or disk exceeds thresholds, the curl *doesn't fire*, and Uptime Kuma flags it as down

**Success criteria:**
- Uptime Kuma shows a "Server Resources" monitor alongside OpenClaw
- If you artificially spike resource usage (e.g., `stress --cpu 2 --timeout 60` or `dd if=/dev/zero of=/tmp/bigfile bs=1M count=500`), the Push monitor goes yellow/red
- You receive a Telegram alert for resource problems, not just OpenClaw outages

<details>
<summary>Hint 1 -- Push monitor setup</summary>

In Uptime Kuma, create a new monitor with type "Push." It gives you a URL like `http://uptime-kuma:3001/api/push/XXXXX?status=up&msg=OK`. Your script curls that URL to say "I'm fine." If the curl stops coming (because the script detected a problem and skipped it), Kuma flags it.

</details>

<details>
<summary>Hint 2 -- Conditional push</summary>

At the end of your health check script, add logic like:

```bash
if [ "$ALL_OK" = true ]; then
    curl -fsS -m 10 "http://localhost:3001/api/push/YOUR_PUSH_TOKEN?status=up&msg=OK&ping=" > /dev/null
else
    curl -fsS -m 10 "http://localhost:3001/api/push/YOUR_PUSH_TOKEN?status=down&msg=Resource+threshold+exceeded" > /dev/null
fi
```

Note: we use `localhost:3001` here because the health check script runs natively on the host, and Uptime Kuma's port is bound to `127.0.0.1:3001`.

</details>

---

### Challenge 2: Daily Health Digest

**Task:** Set up a daily summary that tells you how your server did over the past 24 hours -- without checking the dashboard.

The idea: a cron job runs once a day, collects key stats, and sends you a Telegram message with the summary. Something like:

```
Daily Health Digest -- Mar 30, 2026
Uptime: 24h 0m (no outages)
CPU avg: 4% | max: 22%
MEM avg: 61% | max: 68%
Disk: 43% (grew 0.2% today)
OpenClaw: running
Containers: cloudflared, uptime-kuma, killswitch all running
```

**What to do:**
- Create a `daily-digest.sh` script that reads the health log, calculates averages and maximums, and sends a summary via Telegram
- Schedule it with cron to run at 8 AM every day
- Use the Telegram Bot API to send the message (you already have the bot token and chat ID)

**Success criteria:**
- You receive a Telegram message every morning at 8 AM with yesterday's stats
- The digest includes uptime, resource averages, resource maximums, and service status (both native OpenClaw and Docker containers)
- You can glance at it in 5 seconds and know if anything needs attention

<details>
<summary>Hint 1 -- Sending a Telegram message from bash</summary>

```bash
BOT_TOKEN="your-bot-token"
CHAT_ID="your-chat-id"
MESSAGE="Your digest text here"

curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
  -d chat_id="${CHAT_ID}" \
  -d text="${MESSAGE}" \
  -d parse_mode="Markdown" > /dev/null
```

</details>

<details>
<summary>Hint 2 -- Parsing the health log</summary>

Your health log has lines like:
```
Wed Mar 30 14:30:00 UTC 2026: CPU=3% MEM=62% DISK=41% -- OK
```

Extract CPU values with:
```bash
grep "$(date -d 'yesterday' '+%b %d')" /var/log/openclaw-health.log | \
  grep -oP 'CPU=\K[0-9]+' | \
  awk '{sum+=$1; if($1>max)max=$1; n++} END {print "avg="int(sum/n) " max="max}'
```

</details>

---

### Challenge 3: The Panic Button (Kill Everything)

**Task:** Create a "panic mode" that kills ALL services, not just OpenClaw. For when things are really, truly on fire.

Your current kill switch only stops native OpenClaw. But what if the problem is in another service? What if a Docker container is somehow being exploited, or the kill switch container itself is compromised? You need a scorched-earth option that doesn't require the VPS provider app.

**What to do:**
- Create a `panic.sh` script that stops native OpenClaw AND all Docker containers
- Add a third secret URL to your kill switch service for the panic mode
- Bookmark it on your phone with a distinctive label (like "PANIC -- KILL ALL")
- Test it: trigger panic, verify everything stops, verify you can still SSH in and revive

**Success criteria:**
- Tapping the panic bookmark stops native OpenClaw and every Docker container
- Only the host OS and SSH remain accessible (no tunnel, no monitoring, no nothing)
- You can SSH in and revive: `openclaw gateway start && docker compose up -d`
- The panic script logs what it did, with timestamps

<details>
<summary>Hint 1 -- Stopping everything</summary>

The panic script needs to stop both native OpenClaw and all Docker containers:

```bash
openclaw gateway stop
cd /home/openclaw/openclaw-deploy && docker compose stop
```

Note: `docker compose stop` just stops containers, so `docker compose start` brings them back faster than `docker compose up -d`.

</details>

<details>
<summary>Hint 2 -- Adding a third URL to the kill switch</summary>

In your docker-compose.yml, the killswitch command already checks for KILL_SECRET and REVIVE_SECRET. Add a third check:

```bash
elif grep -q "$$PANIC_SECRET" /tmp/request.txt; then
  sh /killswitch/panic.sh
fi
```

And add the `PANIC_SECRET` environment variable.

</details>

---

## Solution

<details>
<summary>Full solution for all three challenges</summary>

### Challenge 1: Push Monitor

Add a Push monitor in Uptime Kuma (Monitor Type: Push, heartbeat interval 5 minutes, retries 1). Copy the push URL.

At the end of your health check script:

```bash
ALL_OK=true

if [ "$CPU_USAGE" -gt "$CPU_THRESHOLD" ]; then
    ALL_OK=false
fi
if [ "$MEM_USAGE" -gt "$MEM_THRESHOLD" ]; then
    ALL_OK=false
fi
if [ "$DISK_USAGE" -gt "$DISK_THRESHOLD" ]; then
    ALL_OK=false
fi

if [ "$ALL_OK" = true ]; then
    curl -fsS -m 10 "http://localhost:3001/api/push/YOUR_TOKEN?status=up&msg=OK" > /dev/null
else
    curl -fsS -m 10 "http://localhost:3001/api/push/YOUR_TOKEN?status=down&msg=Threshold+exceeded" > /dev/null
fi
```

### Challenge 2: Daily Digest

Create `/home/openclaw/daily-digest.sh`:

```bash
#!/bin/bash
BOT_TOKEN="your-bot-token"
CHAT_ID="your-chat-id"
LOG="/var/log/openclaw-health.log"
TODAY=$(date '+%b %d')

# Parse today's entries
CPU_STATS=$(grep "$TODAY" "$LOG" | grep -oP 'CPU=\K[0-9]+' | awk '{sum+=$1; if($1>max)max=$1; n++} END {printf "avg=%d max=%d", sum/n, max}')
MEM_STATS=$(grep "$TODAY" "$LOG" | grep -oP 'MEM=\K[0-9]+' | awk '{sum+=$1; if($1>max)max=$1; n++} END {printf "avg=%d max=%d", sum/n, max}')
DISK=$(grep "$TODAY" "$LOG" | grep -oP 'DISK=\K[0-9]+' | tail -1)

# Check services
OPENCLAW_STATUS=$(openclaw gateway status 2>/dev/null | grep -q "running" && echo "running" || echo "DOWN")
CONTAINERS=$(docker compose -f /home/openclaw/openclaw-deploy/docker-compose.yml ps --format json | grep -c '"running"')

MESSAGE="*Daily Health Digest -- $(date '+%b %d, %Y')*
CPU: ${CPU_STATS}%
MEM: ${MEM_STATS}%
Disk: ${DISK}%
OpenClaw: ${OPENCLAW_STATUS}
Docker containers running: ${CONTAINERS}"

curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
  -d chat_id="${CHAT_ID}" \
  -d text="${MESSAGE}" \
  -d parse_mode="Markdown" > /dev/null
```

Cron entry: `0 8 * * * /home/openclaw/daily-digest.sh`

### Challenge 3: Panic Button

Create `config/killswitch/panic.sh`:

```bash
#!/bin/sh
echo "$(date): PANIC -- stopping ALL services" >> /var/log/killswitch.log
openclaw gateway stop
cd /home/openclaw/openclaw-deploy && docker compose stop
```

Add to the killswitch service in docker-compose.yml:
- Mount: `./config/killswitch/panic.sh:/killswitch/panic.sh:ro`
- Environment: `PANIC_SECRET=<your-panic-secret>`
- Add the `elif` check in the command

</details>

---

## Reflection

After completing the challenges, think about:

- **How fast can you respond?** From "phone buzzes" to "agent is stopped," what's your best time?
- **What's your morning routine?** A daily digest means you start each day knowing your server's status without checking anything.
- **When would you actually use the panic button?** It's scorched earth -- everything dies. What scenario justifies it over the targeted kill?
- **What would you do at 3 AM?** For a personal project, the answer should be "go back to sleep and fix it in the morning." But knowing things broke is still valuable -- you can check logs when you wake up.

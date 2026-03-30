# Challenge 10: Stress Test Your Monitoring

## The Scenario

It's 2 AM. Your bot crashes. How long until you find out?

That's what we're going to measure. You've built three layers of monitoring -- now let's find out if they actually work under pressure. You'll intentionally break things, time your alerts, and extend your monitoring to cover services beyond just OpenClaw.

## Your Mission

Complete all three challenges to prove your monitoring stack is production-ready.

---

### Challenge 1: Time Your Alert Pipeline

**Task:** Stop OpenClaw, start a timer, and measure exactly how long until you receive a notification on your phone/email/Discord.

**Success criteria:**
- You have a measured time from "service down" to "alert received"
- The time is under 3 minutes
- You receive both a "down" and a "recovered" notification

<details>
<summary>Hint 1 -- How to time it</summary>

Run this right before stopping OpenClaw:

```bash
echo "Stopped at: $(date)" && cd ~/openclaw-stack && docker compose stop openclaw
```

Check the timestamp on the notification when it arrives. The difference is your alert latency.

</details>

<details>
<summary>Hint 2 -- If you're not getting alerts</summary>

Check Uptime Kuma's monitor settings. Is the heartbeat interval set to 60 seconds? Are retries configured? Go to your notification settings and hit "Test" to verify the notification channel works independently of the monitor.

</details>

---

### Challenge 2: Monitor the Tunnel and SearXNG

**Task:** Add Uptime Kuma monitors for Cloudflare Tunnel and SearXNG, so you're not just watching OpenClaw.

Right now, if your tunnel goes down, OpenClaw keeps running happily -- but nobody can reach it. If SearXNG crashes, your bot loses web search. These are silent failures that your current monitoring misses.

**Success criteria:**
- You have an Uptime Kuma monitor for SearXNG
- You have an Uptime Kuma monitor for the tunnel (or a creative alternative)
- Stopping SearXNG triggers an alert

<details>
<summary>Hint 1 -- What URLs to monitor</summary>

SearXNG runs on the Docker network. Think about what URL Uptime Kuma can reach it at, and what port SearXNG listens on.

For the tunnel, think about what it would mean to monitor the tunnel "from inside." Can you check if the `cloudflared` container is running? Or could you monitor your public URL from an external check?

</details>

<details>
<summary>Hint 2 -- Specific URLs</summary>

SearXNG: `http://searxng:8080` -- add as an HTTP monitor in Uptime Kuma.

For the tunnel: you can't easily HTTP-check `cloudflared` from inside, but you *can* add a "Docker Container" monitor type in Uptime Kuma (if available in your version) or use Healthchecks.io to ping your public URL from outside. Another approach: add a `docker ps | grep -q cloudflared` check to your health check script.

</details>

---

### Challenge 3: Customize Your Health Check Thresholds

**Task:** Your health check script uses 80% for all thresholds. But those might not be right for *your* server. Analyze your actual usage patterns and set smarter thresholds.

**Success criteria:**
- You've reviewed at least a few hours of health log data
- You've adjusted at least one threshold based on actual usage
- You can explain *why* you chose the thresholds you did

<details>
<summary>Hint -- How to analyze your logs</summary>

After your cron job has been running for a few hours:

```bash
cat /var/log/openclaw-health.log
```

Look at the pattern. If memory is consistently at 65%, setting the threshold at 70% will give you false alarms. Setting it at 90% might be too late. A good rule: set the threshold at roughly 1.5x your normal usage, capped at 90%.

For disk, check your growth rate. If you're at 40% and growing 1% per day, an 80% threshold gives you 40 days of warning. That's probably fine. If you're growing 5% per day, you need a lower threshold or a cleanup job.

</details>

---

## Solution

<details>
<summary>Full solution and explanation</summary>

### Challenge 1: Alert Timing

Typical alert latency with the recommended settings:

- **Uptime Kuma** checks every 60 seconds with 3 retries at 30-second intervals
- Worst case: you stop OpenClaw right after a check. Next check in 60s fails, then 3 retries at 30s each = 60 + 90 = **150 seconds** (2.5 minutes)
- Best case: you stop it right before a check = about **90 seconds**
- Average: roughly **2 minutes**

If you're getting slower alerts, reduce the heartbeat interval (but don't go below 30 seconds -- that's where alert fatigue territory starts for a personal project).

### Challenge 2: Additional Monitors

**SearXNG monitor in Uptime Kuma:**
- Type: HTTP(s)
- URL: `http://searxng:8080`
- Interval: 60 seconds

**Tunnel monitoring -- two approaches:**

*Approach A (from health check script):*
Add to `healthcheck.sh`:
```bash
if ! docker ps | grep -q cloudflared; then
    echo "ALERT: Cloudflare Tunnel is DOWN -- restarting..."
    cd /home/openclaw/openclaw-stack && docker compose restart cloudflared
fi
```

*Approach B (external URL check via Healthchecks.io):*
Create a second Healthchecks.io check and add a curl to your public URL:
```bash
curl -fsS -m 10 https://yourdomain.com/health > /dev/null && \
  curl -fsS -m 10 https://hc-ping.com/YOUR_TUNNEL_CHECK_UUID > /dev/null
```
This checks the full chain: server + tunnel + application.

Approach B is stronger because it tests from the outside, but Approach A is simpler and catches container crashes fast. Use both if you want belt-and-suspenders.

### Challenge 3: Threshold Tuning

There's no single right answer -- it depends on your server and workload. But here's a framework:

| Resource | Normal Range (typical $5 Lightsail) | Suggested Threshold | Why |
|----------|-------------------------------------|--------------------|----|
| CPU | 2-10% idle, spikes to 40-60% during messages | 80% | CPU spikes are normal; sustained high CPU means trouble |
| Memory | 55-70% | 85% | Memory tends to be stable; crossing 85% means you're close to OOM |
| Disk | 30-50%, growing slowly | 80% | Gives you time to clean up before you hit 100% |

The key insight: thresholds should trigger when something is *abnormal*, not when the server is busy doing its job. A CPU spike to 60% while processing a message is fine. CPU stuck at 80% for 5 minutes is not.

</details>

---

## Reflection

After completing the challenges, think about:

- **What's your actual alert latency?** Is it fast enough for a personal project? What about something others depend on?
- **What blind spots remain?** Is there anything that could fail silently even with all three monitoring layers?
- **What would you do** if you got an alert at 3 AM? (The answer should be "go back to sleep and fix it in the morning" for a personal project. But knowing things broke is still valuable -- you can check logs in the morning and understand what happened.)

Next up: Module 11 gives you the tools to *act* on what monitoring tells you -- the kill switch.

# Lesson 10: Is It Still Alive? -- Monitoring and Alerts

## Your Server's Check Engine Light

You know that little orange light on your car's dashboard? The one that says "something's wrong, go look at this"? You probably don't think about it much -- until it comes on. And if someone ripped it out of the dashboard entirely, you'd still *drive* fine... right up until the engine seizes.

Running a server without monitoring is the same thing. Everything seems great. The bot responds. The server hums along. And then one day it doesn't, and you have no idea when it stopped working, or why.

## Completing the Trifecta

Let's take stock. In Module 5, we identified the three things that get servers owned -- the lethal trifecta:

1. **Open ports** -- fixed in Module 7 with Cloudflare Tunnel. Your server has zero inbound ports except SSH.
2. **Exposed secrets** -- fixed in Module 6 with Docker Secrets. Your API keys are not in environment variables or `.env` files.
3. **No monitoring** -- that's this module. Right now, your bot could be down and you'd have no idea.

After today, the trifecta is complete. You'll have defended against all three.

## What "Monitoring" Actually Means

Monitoring isn't one thing -- it's a few different ideas working together:

**Resource monitoring** answers "is my server healthy?" Are CPU, memory, and disk usage within normal ranges? If your disk fills up, containers crash. If memory maxes out, the Linux OOM killer starts terminating processes (and it has terrible taste in what it picks). You want to know *before* you hit the wall.

**Service monitoring** answers "is my application running?" The server could be perfectly healthy while your Docker container sits there crashed. OpenClaw could have exited 6 hours ago and your VPS is fine -- just useless.

**Uptime monitoring** answers "can the outside world reach my service?" Your container might be running, but the Cloudflare Tunnel could be down, or the health endpoint might be returning errors. An external check verifies the whole chain works, end to end.

**Alerting** ties it all together. Monitoring without alerts is a dashboard nobody looks at. You need notifications that reach you -- on your phone, in your inbox, wherever you'll actually see them.

## Health Checks: The Simplest Approach

The foundation of our monitoring is a bash script. Unsexy? Absolutely. Effective? Extremely.

A health check script does a few things:

1. **Checks resource usage** -- reads CPU, memory, and disk utilization
2. **Checks service status** -- verifies key containers are running
3. **Takes action** -- optionally restarts crashed services
4. **Logs everything** -- writes results to a file so you can look back

The key commands are straightforward:

```bash
# CPU usage (as a percentage)
top -bn1 | grep "Cpu(s)" | awk '{print int($2)}'

# Memory usage (as a percentage)
free | awk '/Mem/{printf("%d"), $3/$2*100}'

# Disk usage (as a percentage)
df / | awk 'NR==2{print int($5)}'

# Is a specific container running?
docker ps | grep -q openclaw
```

Each of these returns a number you can compare against a threshold. If any of them cross the line, you know something needs attention.

> **Pro tip:** The `top -bn1` command runs `top` in batch mode (`-b`) for one iteration (`-n1`), which gives you a snapshot you can parse. Without `-b`, `top` opens its interactive display, which is useless in a script.

## Cron: Linux's Built-in Scheduler

You've written a script. Now you need it to run every 5 minutes without you doing anything. That's what cron is for.

Cron is one of those Unix tools that's been around since the 1970s and still works exactly the same way. It runs tasks on a schedule. The schedule is defined in a *crontab* -- a file where each line says "run this command at these times."

The format looks cryptic at first:

```
* * * * * command
| | | | |
| | | | +-- day of week (0-7, where 0 and 7 are Sunday)
| | | +---- month (1-12)
| | +------ day of month (1-31)
| +-------- hour (0-23)
+---------- minute (0-59)
```

Some examples:

```bash
# Every 5 minutes
*/5 * * * * /home/openclaw/healthcheck.sh

# Every hour on the hour
0 * * * * /some/script.sh

# Every day at 3 AM
0 3 * * * /some/script.sh

# Every Monday at 9 AM
0 9 * * 1 /some/script.sh
```

The `*/5` syntax means "every 5th minute." You edit your crontab with `crontab -e` and add a line. That's it -- cron picks it up automatically.

One critical detail: cron output goes to email by default (which you probably don't have configured on your server). So you redirect output to a log file:

```bash
*/5 * * * * /home/openclaw/healthcheck.sh >> /var/log/openclaw-health.log 2>&1
```

The `>> /var/log/openclaw-health.log` appends stdout to the log file. The `2>&1` redirects stderr there too. Without this, your script runs but you never see the output.

## Uptime Kuma: Monitoring With a Dashboard

A health check script running via cron is solid, but it only monitors from *inside* the server. If the server itself goes down, the script goes with it.

Uptime Kuma is a self-hosted monitoring tool that gives you a web dashboard, multiple check types, and push notifications. It's already in your Docker Compose stack from Module 9 -- we just need to configure it.

Uptime Kuma supports several monitor types, but we care about two:

**HTTP(S) monitors** -- Kuma pings a URL and checks for a 200 response. You'll point it at OpenClaw's internal health endpoint (`http://openclaw:3000/health`) over the Docker network. If it stops responding, Kuma flags it.

**Push monitors** -- instead of Kuma pinging your service, your service pings Kuma. This is the dead-man's switch pattern: "If I stop hearing from you, something is wrong." You'll add a curl to your health check script that pings Kuma every 5 minutes. If Kuma doesn't hear from the script, it fires an alert.

The dashboard is accessible via your Cloudflare Tunnel at `status.yourdomain.com`, so you can check it from your phone anywhere.

## External Monitoring: The Dead-Man's Switch

Here's the problem with self-hosted monitoring: if your server dies, your monitoring dies with it. Uptime Kuma can't alert you about a server crash if Uptime Kuma *is on that server*.

That's where external services like Healthchecks.io come in. The concept is simple:

1. Your health check script pings an external URL every 5 minutes
2. Healthchecks.io expects those pings on schedule
3. If the pings stop, *they* email you

This is called a dead-man's switch. It doesn't check *if* something is wrong -- it checks if you *stopped reporting that things are fine*. Subtle but powerful difference.

Healthchecks.io has a generous free tier (20 checks), and the integration is one line added to your health check script:

```bash
curl -fsS -m 10 --retry 5 https://hc-ping.com/YOUR_UUID > /dev/null
```

That's it. If this curl stops being called, you get an email.

## Reading docker stats

One more tool worth knowing: `docker stats`. It shows live resource usage per container:

```
CONTAINER    CPU %   MEM USAGE / LIMIT    NET I/O          BLOCK I/O
openclaw     2.5%    256MiB / 1GiB        15MB / 8MB       50MB / 10MB
searxng      0.3%    128MiB / 1GiB        2MB / 1MB        10MB / 5MB
cloudflared  0.1%    32MiB / 1GiB         500kB / 300kB    1MB / 0B
uptime-kuma  0.5%    64MiB / 1GiB         1MB / 500kB      5MB / 2MB
```

The columns that matter most:

- **CPU %** -- how much processing each container uses. OpenClaw will spike when processing messages, but should idle low.
- **MEM USAGE / LIMIT** -- current memory vs the maximum available. If these numbers get close, you're in trouble.
- **NET I/O** -- network traffic in/out. Useful for spotting unusual activity.

Use `docker stats --no-stream` for a single snapshot (good for scripts) or just `docker stats` for a live view (hit Ctrl+C to exit).

## Alert Fatigue: The Real Enemy

Here's a mistake everyone makes the first time they set up monitoring: they monitor *everything*. CPU goes above 50%? Alert. Memory above 60%? Alert. Any container restarts? Alert.

Within a day, you're ignoring all the alerts. This is alert fatigue, and it's more dangerous than no monitoring at all -- because at least with no monitoring, you *know* you're flying blind. With alert fatigue, you *think* you're monitoring but you've trained yourself to ignore the alerts.

The fix: only alert on things that require action.

- CPU at 80% for 5 minutes? That's worth knowing -- it might mean a runaway process.
- CPU at 50%? That's normal operation. Don't alert.
- OpenClaw container down? Absolutely alert -- and auto-restart it.
- Disk at 80%? Alert -- you need to clean up before you hit 100% and everything crashes.

Set your thresholds high enough that when an alert fires, it *means something*. You should feel a small jolt of "oh, I need to look at this" -- not "oh, another one of those."

> **Pro tip:** Start with higher thresholds (80%) and lower them later if you find problems creeping up undetected. It's easier to add sensitivity than to recover from alert fatigue.

## The Bigger Picture

Monitoring isn't about catching every possible problem. It's about catching the problems that matter *fast enough to act on them*. A bot that's been down for 30 seconds is a non-event. A bot that's been down for 12 hours because nobody noticed? That's the scenario we're eliminating.

With this module, you'll have three layers of monitoring:

1. **Health check script (cron)** -- checks every 5 minutes from inside the server, auto-restarts crashed containers, logs everything
2. **Uptime Kuma** -- web dashboard with HTTP checks and push notifications, accessible from your phone
3. **Healthchecks.io (optional)** -- external dead-man's switch that catches total server failures

Each layer covers a blind spot the others miss. Together, they mean you'll know about problems within a minute or two, not hours or days.

And with that, the lethal trifecta is complete. Tunnel locks the doors. Secrets hides the keys. Monitoring watches the cameras. Let's set it up.

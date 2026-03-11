# Challenge 11: Full Emergency Drill

## The Scenario

It's 11pm on a Tuesday. You glance at your phone and see a Telegram notification from Uptime Kuma: "OpenClaw health check FAILED." You open WhatsApp and see your bot has sent 47 identical messages to your test number in the last 3 minutes. Something is very wrong, and your Claude API bill is climbing.

This isn't hypothetical anymore -- you have the tools, and now you need the reflexes. Your challenge: run a full emergency drill. Trigger every kill method, time the recovery, and verify monitoring catches each outage. Do it until it's boring. Boring means you're ready.

## Your Task

1. **Level 1 drill** -- Kill via bookmark URL from your phone. Time from tap to confirmed stop.
2. **Revive** -- Bring OpenClaw back. Verify it's healthy (responds to a WhatsApp message). Note the time.
3. **Level 2 drill** -- Kill via WhatsApp kill phrase. Time from send to confirmed stop.
4. **Revive** -- Same as above.
5. **Level 3 drill** -- Kill via SSH one-liner. Time from opening terminal to confirmed stop.
6. **Revive** -- Same as above.
7. **Level 4 drill** -- Kill via VPS provider app (power off). Time from tap to confirmed everything-down.
8. **Full revive** -- Power back on, SSH in, bring up all services, verify everything works end-to-end.

For each kill:
- Record the time it took
- Check Uptime Kuma -- did it detect the outage? How quickly?
- Verify the kill switch log (`/var/log/killswitch.log` for Level 1)

## Success Criteria

- All four kill methods work
- You can revive from each kill without looking at notes
- Uptime Kuma detects at least the Level 1 and Level 4 outages
- Your fastest Level 1 kill-to-confirmed-stop time is under 10 seconds
- Full Level 4 revive (power on through healthy bot response) is under 5 minutes
- Your escalation playbook is filled in with real values and saved on your phone

## Hints

<details>
<summary>Hint 1: If Level 4 revive takes too long</summary>

After powering on the server, it can take 30-90 seconds for the OS to boot and Docker to start. If `restart: unless-stopped` is set on your services, Docker should auto-start them. But if it doesn't, just run `docker compose up -d` manually. Don't wait -- SSH in as soon as the server accepts connections and start things yourself.

</details>

<details>
<summary>Hint 2: If monitoring doesn't catch it</summary>

Check your Uptime Kuma polling interval. If it's set to check every 60 seconds, a kill-and-revive that completes in 30 seconds might slip through undetected. For this drill, you can temporarily lower the check interval to 15 seconds.

</details>

## Solution

The solution for this challenge isn't code -- it's a completed drill log. Here's what a successful drill looks like:

<details>
<summary>Click to reveal example drill results</summary>

### Example Drill Log

```
EMERGENCY DRILL -- [date]
================================

LEVEL 1: Bookmark URL
  Kill time: 4 seconds (tap bookmark → docker ps shows "Exited")
  Uptime Kuma alert: Yes, 45 seconds after kill
  Revive time: 8 seconds (docker compose up -d openclaw → healthy logs)
  Killswitch log entry: confirmed at /var/log/killswitch.log

LEVEL 2: WhatsApp Kill Phrase
  Kill time: 6 seconds (send message → docker ps shows "Exited")
  Uptime Kuma alert: Yes, 50 seconds after kill
  Revive time: 8 seconds
  Note: Phrase must be exact -- "EMERGENCY STOP NOW" (all caps)

LEVEL 3: SSH One-Liner
  Kill time: 12 seconds (open Termius → run saved snippet → confirmed)
  Uptime Kuma alert: Yes, 30 seconds after kill
  Revive time: 10 seconds

LEVEL 4: VPS Provider App (Nuclear)
  Kill time: 8 seconds (open app → power off → confirmed)
  Full revive time: 3 minutes 20 seconds
    - Server boot: ~75 seconds
    - SSH available: ~90 seconds
    - docker compose up -d: ~15 seconds
    - First healthy response: ~40 seconds
  Uptime Kuma: Alert at ~60 seconds (then went offline itself)
  All services verified green after revive

ESCALATION PLAYBOOK: saved on phone (Notes app), printed copy at desk
TOTAL DRILL TIME: ~25 minutes
```

### Recovery commands cheat sheet

```bash
# After Level 1, 2, or 3 kill:
docker compose ps                    # See what's running
docker compose up -d openclaw        # Restart just OpenClaw
docker compose logs -f openclaw      # Verify healthy startup

# After Level 4 kill (full server power-off):
# 1. Power on via provider app/dashboard
# 2. Wait ~90 seconds
ssh openclaw@<your-vps-ip>
cd ~/openclaw-stack
docker compose up -d                 # Start everything
docker compose ps                    # Verify all services
docker compose logs -f               # Watch for errors
```

### Why drill repeatedly?

The first time you run this drill, you'll fumble. You'll forget which app has the bookmark, or you'll mistype the SSH command, or you'll accidentally try to restart before checking what's actually down. That's the whole point -- better to fumble now than at 2am when your bot is burning money.

Run this drill once a month. It takes 20 minutes and it keeps the muscle memory fresh.

</details>

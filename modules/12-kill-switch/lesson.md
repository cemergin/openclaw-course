# Lesson 11: The Kill Switch -- Emergency Stop from Your Phone

## The $200 Nap

Here's a story that's happened to more than a few people running AI agents: you set up your bot on Friday evening, everything's working great, you go to bed feeling like a genius. You wake up Saturday morning to an email from Anthropic saying you've burned through $200 in API credits overnight. Your bot got stuck in a loop -- maybe it was retrying a failed request, maybe someone sent it a message that triggered recursive processing. Doesn't matter. The money's gone.

Or here's a scarier one: someone figures out your bot accepts messages, and sends it a carefully crafted prompt injection that tells it to forward all future messages to a different number. Your bot happily complies, because from its perspective, that was just another instruction.

These aren't hypothetical. AI agents operate autonomously. That's the whole point -- and also the whole risk. Unlike a web app that just serves pages, your agent *takes actions*. It calls APIs. It spends money. It processes data. And it does all of this without checking with you first.

You need an off switch. Multiple off switches, actually, because the one time you need it most might be the one time your primary method doesn't work.

## The Four Escalation Levels

We're building four independent kill methods, ordered from most convenient to most destructive:

**Level 1: Secret URL bookmark.** Tap a bookmark on your phone. OpenClaw stops. Everything else keeps running. This is your go-to.

**Level 2: WhatsApp kill phrase.** Send a specific message through WhatsApp. OpenClaw catches it before the AI processes it and shuts itself down. Works when you have WhatsApp open but not a browser.

**Level 3: SSH one-liner.** Run a single command from any terminal. More work to get to (you need a terminal app), but gives you full control.

**Level 4: VPS provider mobile app.** Open the Hetzner/AWS/DigitalOcean app and hit the power button. Kills *everything* -- OpenClaw, monitoring, tunnel, the whole server. This is the "glass break in case of fire" option.

Why four? Because defense in depth isn't just for security -- it's for operations too. If Cloudflare is having an outage, Level 1 won't work. If your WhatsApp integration is the thing that's broken, Level 2 won't help. If you don't have a terminal handy, Level 3 is out. Level 4 always works, but it's scorched earth.

## Level 1: The Secret URL Kill Endpoint

This is the clever one. Here's how it works:

You create a tiny container that has one job: when it receives an HTTP request at a specific secret path, it stops the OpenClaw container. That's it. It's a one-trick pony, and that's exactly what you want from a kill switch -- simple enough that there's nothing to break.

The secret URL looks like this:

```
https://openclaw.yourdomain.com/killswitch/kill-a1b2c3d4e5f6a1b2c3d4e5f6
```

That long random string at the end is your kill secret. Anyone who doesn't know it gets a 404. Anyone who does know it can stop your bot with a single HTTP request.

### How It Works Under the Hood

The kill container is a minimal Alpine Linux image running a tiny shell script behind a lightweight HTTP server. It mounts the Docker socket -- `/var/run/docker.sock` -- which is the Unix socket that Docker uses to control containers.

If you remember from Module 4, containers are normally isolated from each other. They can't reach out and touch other containers. But the Docker socket is the master control panel. Any process that can talk to the Docker socket can start, stop, inspect, or delete *any* container on the host.

> **Pro tip:** Mounting the Docker socket into a container is powerful and dangerous. Only give it to containers you trust completely. In our case, the kill switch container runs a script *you* wrote with a secret *you* generated. It's a controlled, deliberate use.

The flow:

1. You tap the bookmark on your phone
2. The request goes to Cloudflare (HTTPS)
3. Cloudflare routes it through your tunnel to the kill switch container
4. The container checks the secret in the URL path
5. If it matches, the script runs `docker stop openclaw`
6. OpenClaw stops. The kill switch container, monitoring, and tunnel keep running.

That last point matters: because the kill switch and monitoring are separate containers, they survive the kill. Uptime Kuma will notice OpenClaw went down and alert you (confirming the kill worked). The tunnel stays up so you can trigger the kill switch again if needed, or so monitoring can still be accessed remotely.

### Generating a Kill Secret

Don't use a password you'll remember. Use randomness:

```bash
echo "kill-$(openssl rand -hex 12)"
```

This gives you something like `kill-a1b2c3d4e5f6a1b2c3d4e5f6`. Long enough to be unguessable, prefixed with `kill-` so you recognize it in your browser history.

### The Kill Script

The script itself is almost comically simple:

```bash
#!/bin/sh
docker stop openclaw
echo "$(date): Kill switch triggered" >> /var/log/killswitch.log
```

That's the whole thing. Stop the container, log that it happened. Simple is good here -- fewer moving parts means fewer things that can fail when you actually need this.

## Level 2: WhatsApp Kill Phrase

This one piggybacks on your existing WhatsApp integration. You configure OpenClaw to watch for a specific hardcoded phrase -- before the message ever reaches the AI model.

```yaml
kill_phrase: "EMERGENCY STOP NOW"
kill_action: shutdown
```

The key word there is *before*. This is a string match that happens in the message processing pipeline, upstream of the AI. It doesn't matter if the AI has been prompt-injected or is behaving erratically -- the kill phrase is checked first, and it triggers a shutdown of the OpenClaw service.

This is useful when you're already in WhatsApp (maybe you just noticed weird replies from your bot) and want to stop it without switching apps.

## Level 3: SSH One-Liner

If you have any terminal app on your phone (or you're at a computer), one command does it:

```bash
ssh root@your-vps-ip "cd /home/openclaw/openclaw-stack && docker compose stop openclaw"
```

This SSHs into your server and stops just the OpenClaw container. Everything else keeps running. It's the same as Level 1 but through a different channel.

## Level 4: VPS Provider Mobile App (Nuclear)

Every major cloud provider has a mobile app:

- **AWS Lightsail** -- tap your instance, hit Stop
- **Hetzner Cloud** -- tap your server, Power Off
- **DigitalOcean** -- tap your droplet, Power Off

This kills the entire virtual machine. Not just OpenClaw -- everything. Monitoring goes dark, the tunnel drops, SSH stops working. The server is just... off.

Use this when: you can't reach the server through any other method (Cloudflare outage, SSH broken, something deeply wrong), or when you want to be absolutely certain everything has stopped.

## The Escalation Playbook

Memorize this. Seriously. When your bot is doing something bad, you won't have time to look it up.

| Level | Method | What it kills | Revive command |
|-------|--------|--------------|----------------|
| 1 | Bookmark URL | OpenClaw only | `docker compose up -d openclaw` |
| 2 | WhatsApp kill phrase | OpenClaw only | `docker compose restart openclaw` |
| 3 | SSH one-liner | OpenClaw container | `docker compose up -d` |
| 4 | VPS app power off | Everything | Power On, SSH in, `docker compose up -d` |

Start at Level 1. If it doesn't work within 30 seconds, go to Level 2. Then 3. Then 4. Don't waste time debugging *why* a method isn't working -- just escalate. You can investigate later, after the bleeding has stopped.

## Reviving After a Kill

Stopping is the easy part. Getting back to normal without breaking things takes a little more care.

After a Level 1, 2, or 3 kill (where only OpenClaw stopped):

```bash
docker compose ps          # Check what's still running
docker compose up -d openclaw  # Restart just OpenClaw
docker compose logs -f openclaw  # Watch the logs to verify it's healthy
```

After a Level 4 kill (where everything stopped):

```bash
# Power the server back on through your provider app or dashboard
# Wait ~60 seconds for it to boot
ssh openclaw@your-vps-ip
cd ~/openclaw-stack
docker compose up -d       # Start everything
docker compose ps          # Verify all services are running
docker compose logs -f     # Watch for any errors
```

The `restart: unless-stopped` policy in your compose file means that after a server reboot, Docker *should* auto-start your containers. But after a manual power-off, it's better to be explicit and bring things up yourself so you can watch the logs.

## The Bigger Picture

The kill switch completes your operational toolkit. You can now deploy (Module 9), monitor (Module 10), and emergency-stop (this module) your AI agent. That's the trifecta of responsible AI agent operations: run it, watch it, and be able to pull the plug.

Think of it like driving a car. Module 9 taught you to drive. Module 10 is the dashboard gauges. This module is the brakes. You wouldn't drive without brakes, and you shouldn't run an autonomous AI agent without a kill switch.

Now let's build all four levels.

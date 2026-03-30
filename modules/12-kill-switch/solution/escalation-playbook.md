# Escalation Playbook -- OpenClaw Emergency Stop

Print this. Save it on your phone. Know it cold.

---

## Level 1: Bookmark URL (try this first)

**Kill URL:** `https://openclaw.example.com/killswitch/kill-a1b2c3d4e5f6a1b2c3d4e5f6`

**What it stops:** OpenClaw only (monitoring and tunnel stay up)

**Revive:**
```
ssh openclaw@203.0.113.42
cd ~/openclaw-stack
docker compose up -d openclaw
docker compose logs -f openclaw
```

---

## Level 2: WhatsApp Kill Phrase

**Kill phrase:** `EMERGENCY STOP NOW`

**Send to:** Your OpenClaw WhatsApp number

**What it stops:** OpenClaw only

**Revive:**
```
ssh openclaw@203.0.113.42
cd ~/openclaw-stack
docker compose restart openclaw
```

---

## Level 3: SSH One-Liner

**Command:**
```
ssh openclaw@203.0.113.42 "cd ~/openclaw-stack && docker compose stop openclaw"
```

**What it stops:** OpenClaw container

**Revive:**
```
ssh openclaw@203.0.113.42 "cd ~/openclaw-stack && docker compose up -d openclaw"
```

---

## Level 4: VPS Provider App (NUCLEAR -- kills everything)

**Provider app:** AWS Lightsail (or Hetzner Cloud / DigitalOcean)

**Instance name:** openclaw-prod

**Action:** Power Off / Stop Instance

**What it stops:** EVERYTHING -- server, monitoring, tunnel, all containers

**Revive:**
1. Power On via provider app
2. Wait ~90 seconds for boot
3. SSH in:
```
ssh openclaw@203.0.113.42
cd ~/openclaw-stack
docker compose up -d
docker compose ps
docker compose logs -f
```

---

## Escalation Rule

Start at Level 1. If it doesn't work in 30 seconds, go to Level 2. Then 3. Then 4. Don't debug -- escalate. Investigate later.

---

**My VPS IP:** 203.0.113.42

**Last drill date:** 2026-03-11

**Drill result:** All 4 levels tested. Level 1 kill in 4s. Full Level 4 revive in 3m20s.

# Escalation Playbook -- OpenClaw Emergency Stop (Hybrid Stack)

Print this. Save it on your phone. Know it cold.

---

## Level 1: Bookmark URL (try this first)

**Kill URL:** `https://killswitch.example.com/kill-a1b2c3d4e5f6a1b2c3d4e5f6`

**Revive URL:** `https://killswitch.example.com/revive-f6e5d4c3b2a1f6e5d4c3b2a1`

**What it stops:** Native OpenClaw only (monitoring, tunnel, and Docker services stay up)

**Revive:** Tap the revive bookmark, or:
```
ssh openclaw@203.0.113.42
openclaw gateway start
openclaw gateway status
```

---

## Level 2: SSH One-Liner

**Kill command:**
```
ssh openclaw@203.0.113.42 "openclaw gateway stop"
```

**What it stops:** Native OpenClaw gateway

**Revive:**
```
ssh openclaw@203.0.113.42 "openclaw gateway start"
```

---

## Level 3: VPS Provider App (NUCLEAR -- kills everything)

**Provider app:** AWS Lightsail (or Hetzner Cloud / DigitalOcean)

**Instance name:** openclaw-prod

**Action:** Power Off / Stop Instance

**What it stops:** EVERYTHING -- native OpenClaw, monitoring, tunnel, all Docker containers, the whole server

**Revive:**
1. Power On via provider app
2. Wait ~90 seconds for boot
3. SSH in:
```
ssh openclaw@203.0.113.42
openclaw gateway start
cd ~/openclaw-deploy
docker compose up -d
docker compose ps
openclaw gateway status
```

---

## Escalation Rule

Start at Level 1. If it doesn't work in 30 seconds, go to Level 2. Then 3. Don't debug -- escalate. Investigate later.

---

**My VPS IP:** 203.0.113.42

**Monitor dashboard:** https://monitor.example.com

**Last drill date:** 2026-03-30

**Drill result:** All 3 levels tested. Level 1 kill in 4s. Full Level 3 revive in 3m20s.

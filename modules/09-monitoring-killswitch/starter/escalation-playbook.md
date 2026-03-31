# Escalation Playbook -- OpenClaw Emergency Stop (Hybrid Stack)

Print this. Save it on your phone. Know it cold.

---

## Level 1: Bookmark URL (try this first)

**Kill URL:** `https://killswitch._______________/______________________________`

**Revive URL:** `https://killswitch._______________/______________________________`

**What it stops:** Native OpenClaw only (monitoring, tunnel, and Docker services stay up)

**Revive:** Tap the revive bookmark, or:
```
ssh openclaw@_______________
openclaw gateway start
openclaw gateway status
```

---

## Level 2: SSH One-Liner

**Kill command:**
```
ssh openclaw@_______________ "openclaw gateway stop"
```

**What it stops:** Native OpenClaw gateway

**Revive:**
```
ssh openclaw@_______________ "openclaw gateway start"
```

---

## Level 3: VPS Provider App (NUCLEAR -- kills everything)

**Provider app:** _______________

**Instance name:** _______________

**Action:** Power Off / Stop Instance

**What it stops:** EVERYTHING -- OpenClaw, monitoring, tunnel, all Docker containers, the whole server

**Revive:**
1. Power On via provider app
2. Wait ~90 seconds for boot
3. SSH in:
```
ssh openclaw@_______________
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

**My VPS IP:** _______________

**Monitor dashboard:** https://monitor._______________

**Last drill date:** _______________

**Drill result:** _______________

# Escalation Playbook -- OpenClaw Emergency Stop

Print this. Save it on your phone. Know it cold.

---

## Level 1: Bookmark URL (try this first)

**Kill URL:** `https://______________________________/killswitch/______________________________`

**What it stops:** OpenClaw only (monitoring and tunnel stay up)

**Revive:**
```
ssh openclaw@_______________
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
ssh openclaw@_______________
cd ~/openclaw-stack
docker compose restart openclaw
```

---

## Level 3: SSH One-Liner

**Command:**
```
ssh openclaw@_______________ "cd ~/openclaw-stack && docker compose stop openclaw"
```

**What it stops:** OpenClaw container

**Revive:**
```
ssh openclaw@_______________ "cd ~/openclaw-stack && docker compose up -d openclaw"
```

---

## Level 4: VPS Provider App (NUCLEAR -- kills everything)

**Provider app:** _______________

**Instance name:** _______________

**Action:** Power Off / Stop Instance

**What it stops:** EVERYTHING -- server, monitoring, tunnel, all containers

**Revive:**
1. Power On via provider app
2. Wait ~90 seconds for boot
3. SSH in:
```
ssh openclaw@_______________
cd ~/openclaw-stack
docker compose up -d
docker compose ps
docker compose logs -f
```

---

## Escalation Rule

Start at Level 1. If it doesn't work in 30 seconds, go to Level 2. Then 3. Then 4. Don't debug -- escalate. Investigate later.

---

**My VPS IP:** _______________

**Last drill date:** _______________

**Drill result:** _______________

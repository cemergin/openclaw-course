# Challenge: Make Yourself at Home

## The Scenario

Your server is running, Node.js and OpenClaw are installed, Docker is ready for support services, and you can connect with `ssh openclaw`. But you've only scratched the surface. A good server operator knows their machine like the back of their hand -- where things live, how to customize the environment, and how to manage multiple connections efficiently.

Your mission: customize your SSH config, explore the filesystem with purpose, and set up tmux so you can multitask like a pro.

---

## Task 1: Multi-Host SSH Config

Your `~/.ssh/config` currently has one host entry. Real developers have dozens -- one for each server, plus shortcuts for GitHub and other services.

**What to do:**

1. Add a second host entry to your SSH config that connects as the `ubuntu` user (for admin tasks requiring sudo):

   ```
   Host openclaw-admin
       HostName YOUR_VPS_IP
       User ubuntu
       IdentityFile ~/.ssh/openclaw
       Port 22
   ```

2. Add a host entry for GitHub (this makes git operations cleaner):

   ```
   Host github.com
       IdentityFile ~/.ssh/openclaw
   ```

3. Test both: `ssh openclaw` (deploy user) and `ssh openclaw-admin` (ubuntu user)

**Success criteria:**
- `ssh openclaw` connects as `deploy`
- `ssh openclaw-admin` connects as `ubuntu`
- You have at least three Host blocks in your config

---

## Task 2: Explore the Filesystem With Purpose

Don't just wander -- answer these specific questions by exploring. SSH in and find:

1. **How much disk space is used vs. available?** (`df -h`)
2. **How much RAM is free?** (`free -h`)
3. **Where is Node.js installed?** (`which node` and `node --version`)
4. **Where is OpenClaw installed?** (`which openclaw`)
5. **What's in /etc/ssh/sshd_config?** Find the line about password authentication. Is it enabled or disabled?
6. **What's in /var/log/?** Can you find the auth log? (Hint: `sudo cat /var/log/auth.log | tail -20`)
7. **Where did Docker install itself?** (Hint: `which docker` and `ls /var/lib/docker/`)

**Bonus:** Check if bots are already probing your server. Look at the auth log for failed login attempts. If your server has been online for more than a few hours, you'll almost certainly see some.

**Success criteria:**
- You can answer all seven questions from memory (or your notes)
- You've checked the auth log and know whether bots are knocking

---

## Task 3: Set Up tmux

`tmux` is a terminal multiplexer -- it lets you have multiple terminal windows inside one SSH session. More importantly, tmux sessions survive if your SSH connection drops. You can reconnect and pick up right where you left off.

**What to do:**

1. Install tmux on your server:

   ```bash
   sudo apt install tmux -y
   ```

2. Start a tmux session:

   ```bash
   tmux new -s openclaw
   ```

3. Learn the essential shortcuts (all start with `Ctrl+b`, then a key):

   | Shortcut | What it does |
   |----------|-------------|
   | `Ctrl+b` then `"` | Split pane horizontally |
   | `Ctrl+b` then `%` | Split pane vertically |
   | `Ctrl+b` then arrow keys | Move between panes |
   | `Ctrl+b` then `d` | Detach (leave tmux running in background) |
   | `Ctrl+b` then `c` | Create a new window |
   | `Ctrl+b` then `n` | Next window |
   | `Ctrl+b` then `p` | Previous window |

4. Practice the detach/reattach cycle:
   - Start something running (like `htop` or `watch free -h`)
   - Detach with `Ctrl+b` then `d`
   - Reattach with `tmux attach -t openclaw`
   - Your process is still running!

5. **The ultimate test:** Start a tmux session, run `htop`, then *close your terminal window entirely*. SSH back in. Run `tmux attach -t openclaw`. Is htop still running?

**Success criteria:**
- You can create, detach from, and reattach to a tmux session
- You can split panes and switch between them
- You understand that tmux survives SSH disconnections

---

## Task 4: Verify the Hybrid Stack

Run a quick sanity check on everything we installed:

```bash
# As the deploy user
ssh openclaw

# Check Node.js
node --version

# Check OpenClaw
openclaw --version

# Check Docker
docker --version
docker compose version

# Check memory usage so far
free -h

# Check disk usage
df -h /
```

How much RAM is free? How much disk space is used? Write it down -- you'll compare these numbers after we deploy the full stack.

**Success criteria:**
- All five version commands work without errors
- You know your baseline memory and disk usage

---

## Hints

<details>
<summary>Hint 1: SSH config formatting</summary>

Each `Host` block must be separated by a blank line. The indentation (4 spaces) under each `Host` line is required. The file is read top to bottom -- if multiple hosts match, the first one wins.

```
Host openclaw
    HostName 123.45.67.89
    User deploy
    IdentityFile ~/.ssh/openclaw
    Port 22
    ServerAliveInterval 60
    ServerAliveCountMax 3

Host openclaw-admin
    HostName 123.45.67.89
    User ubuntu
    IdentityFile ~/.ssh/openclaw
    Port 22

Host github.com
    IdentityFile ~/.ssh/openclaw
```

</details>

<details>
<summary>Hint 2: Reading the auth log</summary>

The auth log records every login attempt:

```bash
# Recent entries
sudo tail -30 /var/log/auth.log

# Just failed attempts
sudo grep "Failed" /var/log/auth.log | tail -20

# Count failed attempts
sudo grep -c "Failed" /var/log/auth.log
```

If you see lines like `Failed password for root from 45.148.10.42`, that's a bot trying to brute-force your server. This is normal and harmless if password authentication is disabled (which we'll do properly when we harden SSH later).

</details>

<details>
<summary>Hint 3: tmux basics</summary>

Think of tmux in layers:
- **Session** = a workspace (you named yours `openclaw`)
- **Window** = a tab within a session
- **Pane** = a split within a window

The most useful daily workflow: SSH in, `tmux attach -t openclaw` (or `tmux new -s openclaw` if no session exists). Do your work in panes. When you're done, detach (`Ctrl+b d`), and disconnect. Everything keeps running.

To list all sessions: `tmux ls`
To kill a session: `tmux kill-session -t openclaw`

</details>

---

## Solution

<details>
<summary>Click to reveal the full solution</summary>

### Task 1: Multi-Host SSH Config

On your local machine, edit `~/.ssh/config`:

```
Host openclaw
    HostName YOUR_VPS_IP
    User deploy
    IdentityFile ~/.ssh/openclaw
    Port 22
    ServerAliveInterval 60
    ServerAliveCountMax 3

Host openclaw-admin
    HostName YOUR_VPS_IP
    User ubuntu
    IdentityFile ~/.ssh/openclaw
    Port 22
    ServerAliveInterval 60
    ServerAliveCountMax 3

Host github.com
    IdentityFile ~/.ssh/openclaw
```

Test:

```bash
ssh openclaw        # Should say "deploy" for whoami
ssh openclaw-admin  # Should say "ubuntu" for whoami
```

### Task 2: Filesystem Exploration

```bash
# 1. Disk space
df -h
# Look at the row for / -- probably something like 39G total, 3G used

# 2. RAM
free -h
# Should show ~957M total, most of it free

# 3. Node.js location
which node              # /usr/bin/node
node --version          # v24.x.x

# 4. OpenClaw location
which openclaw          # /usr/bin/openclaw or /usr/lib/node_modules/.bin/openclaw

# 5. SSH password auth
sudo grep -i "PasswordAuthentication" /etc/ssh/sshd_config
# On a fresh Lightsail instance, it's usually set to "no" or commented out

# 6. Auth log
sudo tail -30 /var/log/auth.log
# You'll see your own successful logins and possibly bot attempts

# 7. Docker location
which docker            # /usr/bin/docker
sudo ls /var/lib/docker # overlay2, containers, image, volumes, etc.
```

### Task 3: tmux Setup

```bash
# Install
sudo apt install tmux -y

# Create a named session
tmux new -s openclaw

# Split horizontally
# Press: Ctrl+b then "

# Split vertically
# Press: Ctrl+b then %

# Run htop in one pane
htop

# Switch panes: Ctrl+b then arrow keys
# In the other pane, run: watch free -h

# Detach: Ctrl+b then d
# You're back to normal shell, but tmux is running

# Reattach
tmux attach -t openclaw
# Both panes are still there!
```

### Task 4: Hybrid Stack Verification

```bash
node --version          # v24.x.x
openclaw --version      # Shows version
docker --version        # Docker version 27.x.x
docker compose version  # Docker Compose version v2.x.x
free -h                 # ~957M total, ~700M free (before running anything)
df -h /                 # ~39G total, ~5G used (OS + Node + Docker)
```

Baseline: you should have roughly 700MB of RAM free and 34GB of disk space available. Plenty of room for OpenClaw and the support services.

</details>

# Challenge: Bulletproof Your Deployment

## The Scenario

Your AI agent is running. Messages go in, responses come out. But right now, if the gateway crashes at 3am, you won't know until you try to use it and get silence. And if the server reboots, the gateway won't start back up on its own. Let's fix both: set up auto-restart with systemd and create a status check script.

---

## Task 1: Create a systemd Service for OpenClaw

Right now, if the gateway crashes or the server reboots, you have to SSH in and manually run `openclaw gateway start`. Let's make it automatic using systemd -- the same system that keeps SSH and Docker running.

**What to do:**

1. SSH in as the admin user (you need sudo):

   ```bash
   ssh openclaw-admin
   ```

2. Create a systemd service file:

   ```bash
   sudo nano /etc/systemd/system/openclaw.service
   ```

3. Paste this configuration:

   ```ini
   [Unit]
   Description=OpenClaw Gateway
   After=network.target

   [Service]
   Type=simple
   User=deploy
   WorkingDirectory=/home/deploy
   ExecStart=/usr/bin/openclaw gateway start --foreground
   Restart=on-failure
   RestartSec=5
   Environment=HOME=/home/deploy

   [Install]
   WantedBy=multi-user.target
   ```

4. Enable and start the service:

   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable openclaw
   sudo systemctl start openclaw
   ```

5. Verify it's running:

   ```bash
   sudo systemctl status openclaw
   ```

6. Test auto-restart by killing the process:

   ```bash
   sudo systemctl kill openclaw
   sleep 10
   sudo systemctl status openclaw
   ```

   The service should restart automatically.

**Success criteria:**
- `systemctl status openclaw` shows the gateway running
- After killing the process, it restarts within a few seconds
- After a reboot (simulated with `sudo systemctl restart openclaw`), the gateway comes back

> **Note:** If `openclaw gateway start --foreground` isn't a valid flag for your version, check `openclaw gateway --help` for the equivalent option. The key is running in foreground mode so systemd can manage the process lifecycle.

---

## Task 2: Create a Status Check Script

Build a simple script that checks the health of your entire deployment -- native OpenClaw AND Docker support services.

**What to do:**

Create a file called `status.sh` in your config repo:

```bash
#!/bin/bash
# status.sh -- Quick health check for OpenClaw deployment

echo "=== OpenClaw Status Check ==="
echo ""

# Check OpenClaw gateway
echo "--- OpenClaw Gateway ---"
openclaw gateway status
echo ""

# Check OpenClaw doctor (quick)
echo "--- OpenClaw Doctor ---"
openclaw doctor
echo ""

# Check support services
echo "--- Support Services (Docker) ---"
cd ~/openclaw
docker compose ps
echo ""

# Check resource usage
echo "--- Resource Usage ---"
echo "Memory:"
free -h | head -2
echo ""
echo "Disk:"
df -h / | tail -1
echo ""

# Check gateway port
echo "--- Gateway Port Check ---"
curl -sf http://127.0.0.1:18789/ > /dev/null && echo "Port 18789: RESPONDING" || echo "Port 18789: NOT RESPONDING"
echo ""

echo "=== Check Complete ==="
```

Push it to your repo, then on the server make it executable:

```bash
chmod +x ~/openclaw/status.sh
```

Run it:

```bash
~/openclaw/status.sh
```

**Success criteria:**
- The script runs and shows gateway status, doctor output, support services, resource usage, and port check
- You can run it anytime to get a quick overview of your deployment's health

---

## Task 3: Simulate a Crash and Recovery

The real test: what happens when things break? Let's find out.

**What to do:**

1. **Stop the gateway** and verify Telegram stops responding:

   ```bash
   openclaw gateway stop
   ```

   Send a Telegram message -- you should get no response (or a delayed error).

2. **Start it back up:**

   ```bash
   openclaw gateway start
   ```

   Send another Telegram message -- it should work again.

3. **Test Docker support service recovery:**

   ```bash
   cd ~/openclaw
   docker compose down
   docker compose up -d
   docker compose ps
   ```

   All services should come back up.

4. **If you completed Task 1 (systemd), test the full auto-recovery:**

   ```bash
   # Kill the gateway process the hard way
   sudo systemctl kill openclaw

   # Wait a few seconds
   sleep 10

   # Check if it came back
   sudo systemctl status openclaw
   openclaw gateway status
   ```

   Send a Telegram message. It should work -- systemd restarted the gateway automatically.

**Success criteria:**
- After manually stopping and starting, the gateway recovers
- After a Docker compose restart, support services recover
- If using systemd, the gateway auto-restarts after a crash
- Your bot responds to Telegram messages after every recovery scenario

---

## Hints

<details>
<summary>Hint 1: systemd service basics</summary>

The key sections of the service file:

- `After=network.target` -- Wait for networking before starting
- `Type=simple` -- The process runs in the foreground (systemd manages it)
- `User=deploy` -- Run as the deploy user, not root
- `Restart=on-failure` -- Restart if the process exits with a non-zero code
- `RestartSec=5` -- Wait 5 seconds before restarting (prevents crash loops)
- `WantedBy=multi-user.target` -- Start when the system reaches normal multi-user mode (i.e., on boot)

Useful systemd commands:

```bash
sudo systemctl status openclaw    # Check current status
sudo systemctl start openclaw     # Start the service
sudo systemctl stop openclaw      # Stop the service
sudo systemctl restart openclaw   # Stop then start
sudo systemctl enable openclaw    # Start on boot
sudo systemctl disable openclaw   # Don't start on boot
sudo journalctl -u openclaw -f   # Follow the logs
```

</details>

<details>
<summary>Hint 2: The status script</summary>

The script should check five things:
1. OpenClaw gateway status (is the process running?)
2. OpenClaw doctor (is the config valid?)
3. Docker support services (are containers running?)
4. System resources (memory, disk)
5. Port check (is the gateway actually responding on 18789?)

The port check is the most important -- a process can be "running" but not actually serving requests (deadlock, bad config, etc.). The `curl` check tells you if the gateway is actually alive and responding.

</details>

<details>
<summary>Hint 3: Debugging gateway startup</summary>

If the gateway won't start:

1. Run `openclaw doctor` -- it checks everything
2. Check if the port is already in use: `sudo lsof -i :18789`
3. Check if there's a stale PID file: `openclaw gateway stop` then `openclaw gateway start`
4. Check memory: `free -h` -- is the server out of RAM?
5. If using systemd, check the journal: `sudo journalctl -u openclaw --since "5 minutes ago"`

Most startup failures are config-related. The doctor will usually tell you exactly what's wrong.

</details>

---

## Solution

<details>
<summary>Click to reveal the full solution</summary>

### Task 1: systemd Service

Create `/etc/systemd/system/openclaw.service` with the configuration shown in the task. Then:

```bash
sudo systemctl daemon-reload
sudo systemctl enable openclaw
sudo systemctl start openclaw
sudo systemctl status openclaw
```

To test auto-restart:

```bash
sudo systemctl kill openclaw
sleep 10
sudo systemctl status openclaw
# Should show "active (running)" with a recent start time
```

To see logs:

```bash
sudo journalctl -u openclaw -f
```

### Task 2: Status Script

Create `status.sh` in your repo with the script shown above. Push it:

```bash
git add status.sh
git commit -m "Add status check script"
git push
```

After deploy, on the server:

```bash
chmod +x ~/openclaw/status.sh
~/openclaw/status.sh
```

Example output:

```
=== OpenClaw Status Check ===

--- OpenClaw Gateway ---
OpenClaw gateway is running (PID 1234)

--- OpenClaw Doctor ---
✓ Node.js version: v24.0.0
✓ Configuration: valid
✓ Workspace: SOUL.md, IDENTITY.md found
✓ API key: configured
✓ Telegram: configured
✓ Network: connected

--- Support Services (Docker) ---
NAME          STATUS
tunnel        Up 2 hours
uptime-kuma   Up 2 hours

--- Resource Usage ---
Memory:
              total   used   free
Mem:          957M    423M   287M

Disk:
/dev/root   39G   5.2G   33G  14% /

--- Gateway Port Check ---
Port 18789: RESPONDING

=== Check Complete ===
```

### Task 3: Crash Simulation

```bash
# Stop gateway manually
openclaw gateway stop
# Send Telegram message -- no response (expected)

# Start gateway
openclaw gateway start
# Send Telegram message -- response! (recovered)

# Docker services
cd ~/openclaw
docker compose down
docker compose up -d
docker compose ps
# All services back

# With systemd (if Task 1 done)
sudo systemctl kill openclaw
sleep 10
sudo systemctl status openclaw
# Auto-restarted! Send Telegram message -- response!
```

### Why This All Matters

- **systemd auto-restart** means your gateway recovers from crashes without you noticing
- **Status scripts** give you a one-command health check
- **Crash simulation** proves your self-healing works (and builds confidence)
- This is the difference between "it works right now" and "it keeps working"

</details>

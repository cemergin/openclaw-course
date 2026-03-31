# Challenge: Audit Your Own Setup

## The Scenario

You've set up a firewall, implemented SecretRef for OpenClaw, and configured Docker secrets for support services. But how do you *know* it's actually working? The best way to verify your defenses is to test them -- attack your own infrastructure, ethically, and find out what's still exposed.

## Task

### Part 1: Port Scan Your Own Server

Use an online port scanner to check what's visible on your VPS from the outside internet.

1. **Before the scan:** Write down what you expect to see. Based on your UFW configuration and the hybrid approach (native OpenClaw + Docker support containers), which ports (if any) should be visible from outside?

2. **Run the scan:** Use one of these free online tools:
   - [https://www.yougetsignal.com/tools/open-ports/](https://www.yougetsignal.com/tools/open-ports/)
   - [https://hackertarget.com/nmap-online-port-scanner/](https://hackertarget.com/nmap-online-port-scanner/)

   Check common ports: 22, 80, 443, 3001, 8080, 18789.

3. **Verify the hybrid approach works:** This is the critical test.
   - Port 18789 (OpenClaw gateway) should be blocked -- UFW handles native processes normally.
   - Port 3001 (Uptime Kuma, if running) should be blocked -- Docker's `127.0.0.1:` binding keeps it local.
   - Port 22 (SSH) should be the only open port.

### Part 2: Verify Secrets Are Hidden

4. **Check OpenClaw's config doesn't contain inline secrets:**

   ```bash
   cat ~/openclaw-deploy/openclaw.json | python3 -c "
   import json, sys
   config = json.load(sys.stdin)
   # This should show SecretRef objects, not actual key values
   print(json.dumps(config, indent=2))
   "
   ```

   You should see `{"source": "file", "id": "..."}` objects, NOT actual API key strings.

5. **Verify no Docker container leaks secrets:**

   ```bash
   for container in $(docker ps -q); do
     name=$(docker inspect --format '{{.Name}}' $container)
     echo "--- $name ---"
     docker inspect $container | grep -i "api_key\|token\|secret\|password" || echo "Clean"
   done
   ```

   Every container should show "Clean" or only show non-sensitive references.

6. **Compare with the old way.** Spin up a temporary container using a `.env` file:

   ```bash
   echo "SECRET_TEST=i-am-visible" > /tmp/test.env
   docker run -d --name leaky --env-file /tmp/test.env alpine sleep 3600
   docker inspect leaky | grep SECRET_TEST
   ```

   See the difference? The `.env` approach exposes everything. Clean up: `docker rm -f leaky && rm /tmp/test.env`

### Part 3: Set Up SSH Key-Only Authentication

This is the big one. Disable password-based SSH login entirely.

7. **First, verify you have SSH key authentication working.** From your local machine, confirm you can SSH in without being prompted for a password:

   ```bash
   ssh openclaw@YOUR_VPS_IP
   ```

   If it asks for a password, you need to set up key-based auth first (refer to Module 3).

8. **Disable password authentication.** On the VPS:

   ```bash
   sudo nano /etc/ssh/sshd_config
   ```

   Find and change (or add) these lines:

   ```
   PasswordAuthentication no
   ChallengeResponseAuthentication no
   UsePAM no
   ```

9. **Restart SSH:**

   ```bash
   sudo systemctl restart sshd
   ```

10. **Test from a new terminal** (keep your current session open as a safety net!):

    ```bash
    ssh openclaw@YOUR_VPS_IP
    ```

    It should connect without asking for a password. If something goes wrong, you still have your original session to fix things.

11. **Try to brute-force yourself.** From your local machine, try SSH with a password:

    ```bash
    ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no openclaw@YOUR_VPS_IP
    ```

    You should get `Permission denied (publickey)`. Nobody can brute-force a password that doesn't exist.

## Success Criteria

- Port scan shows only SSH (port 22) as potentially open -- all other ports are closed/filtered
- Port 18789 is NOT visible from outside (UFW blocks native OpenClaw gateway)
- Port 3001 is NOT visible from outside (Docker `127.0.0.1:` binding works)
- `openclaw.json` contains SecretRef objects, not inline API keys
- `docker inspect` does NOT reveal any API keys or tokens for support containers
- SSH key-only authentication is enabled -- password login is completely disabled
- You can still SSH in normally with your key

---

## Hints

<details>
<summary>Hint 1: Port scan results are unexpected?</summary>

If the online scanner shows ports other than 22 as open, check two things:

1. `sudo ufw status verbose` -- is the firewall actually active?
2. For Docker containers: `docker compose ps` -- look at the "Ports" column. Do you see `0.0.0.0:3001->3001`? That's the problem. It should say `127.0.0.1:3001->3001`.
3. For native OpenClaw: `sudo ss -tlnp | grep 18789` -- it should be listening, but UFW blocks external access. If it shows up in the port scan, verify UFW is active and has default deny incoming.

To fix Docker: update your docker-compose.yml port bindings to use the `127.0.0.1:` prefix and `docker compose up -d` to recreate.

</details>

<details>
<summary>Hint 2: Scared of locking yourself out of SSH?</summary>

Before disabling password auth:

1. Open TWO SSH sessions to your server
2. Make the sshd_config change in one session
3. Restart SSH in that session
4. Test by opening a THIRD session (new connection)
5. Only close the original sessions after the third one works

If something breaks, you still have session #2 to undo the changes. And as a last resort, your VPS provider's web console always works.

</details>

<details>
<summary>Hint 3: Want to go further?</summary>

Once SSH key-only auth is working, consider:

1. **Check your SSH auth log** for past brute-force attempts:
   ```bash
   sudo grep "Failed password" /var/log/auth.log | wc -l
   ```
   The number will likely shock you.

2. **Check UFW block logs:**
   ```bash
   sudo grep "UFW BLOCK" /var/log/syslog | tail -20
   ```

3. **Verify your security checklist** from `starter/security-checklist.md`. Mark off everything you've completed and note what's left for future modules.

</details>

---

## Solution

<details>
<summary>Click to reveal the full solution walkthrough</summary>

### Part 1: Expected Port Scan Results

| Port | Expected Result | Why |
|------|----------------|-----|
| 22   | Open or Filtered | UFW allows SSH |
| 80   | Closed/Filtered | Default deny incoming |
| 443  | Closed/Filtered | Default deny incoming |
| 3001 | Closed/Filtered | Docker bound to 127.0.0.1, invisible from outside |
| 8080 | Closed/Filtered | Default deny incoming |
| 18789 | Closed/Filtered | UFW blocks it -- native OpenClaw respects the firewall |

If port 18789 shows as open, your UFW is not active. Run `sudo ufw enable`.
If port 3001 shows as open, your docker-compose.yml has `"3001:3001"` instead of `"127.0.0.1:3001:3001"`. Fix it.

### Part 2: Secrets Verification

```bash
# OpenClaw config should show SecretRef, not inline keys:
cat ~/openclaw-deploy/openclaw.json
# Look for: {"source": "file", "id": "/home/.../secrets/anthropic_api_key"}
# NOT: "sk-ant-api03-xxxx"

# Docker containers should not leak secrets:
docker inspect cloudflared --format '{{json .Config.Env}}' | python3 -m json.tool
# Should show minimal env vars, no tokens
```

### Part 3: SSH Key-Only Auth

After making the sshd_config changes:

```bash
# Verify the config is correct:
sudo sshd -T | grep -i "passwordauthentication\|challengeresponse\|usepam"

# Expected output:
# passwordauthentication no
# challengeresponseauthentication no
# usepam no
```

### Updated Security Checklist After This Challenge

| Item | Status |
|------|--------|
| UFW enabled, default deny | Done |
| SSH allowed | Done |
| Docker ports use 127.0.0.1: | Done |
| OpenClaw SecretRef configured | Done |
| Docker secrets for support services | Done |
| File permissions locked | Done |
| Auto-updates enabled | Done |
| SSH key-only auth | Done |
| Cloudflare Tunnel | Module 8 |
| Monitoring | Module 9 |
| Kill switch | Module 9 |

</details>

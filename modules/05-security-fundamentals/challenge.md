# Challenge: Attack Your Own Server

## The Scenario

You're a security-conscious developer who just set up a firewall. But how do you know it's actually working? The best way to verify your defenses is to test them -- ethically, on your own infrastructure.

In this challenge, you'll scan your own server from the outside, verify that the firewall is doing its job, and then do a full security audit using the checklist from the lesson.

## Task

### Part 1: Port Scan Your Own Server

Use an online port scanner to check what's visible on your VPS from the outside internet.

1. **Before the scan:** Write down what you expect to see. Based on your UFW configuration, which ports (if any) should respond?

2. **Run the scan:** Use one of these free online tools (they scan from their servers, so they see your VPS the way the internet sees it):
   - [https://www.yougetsignal.com/tools/open-ports/](https://www.yougetsignal.com/tools/open-ports/) -- checks specific ports
   - [https://hackertarget.com/nmap-online-port-scanner/](https://hackertarget.com/nmap-online-port-scanner/) -- runs an nmap scan

   Enter your VPS's static IP and scan common ports: 22, 80, 443, 3000, 8080, 8443.

3. **Analyze the results:** Compare what you expected to what you see.

### Part 2: Test SSH Restrictions

4. Try to access your server from a **different IP** than the one you allowed in UFW. Use your phone's mobile data (not WiFi) or ask a friend to try SSH-ing to your VPS IP.

   ```bash
   ssh openclaw@YOUR_VPS_IP
   ```

   What happens? Document the behavior.

5. Then try from your **allowed IP**. Does it work as expected?

### Part 3: Security Audit

6. Open the `starter/security-checklist.md` file. Go through every item and mark it as:
   - **Done** -- you completed this
   - **Not yet** -- this is covered in a future module (note which one)
   - **N/A** -- doesn't apply to your setup yet

7. For every "Not yet" item, write one sentence about what the risk is *right now* while that item is unfinished.

## Success Criteria

- Port scan shows SSH (port 22) as the only open port (or filtered/closed if scanned from a non-allowed IP)
- Ports 80, 443, 3000, 8080 all show as closed/filtered
- SSH from a non-allowed IP is rejected or times out
- SSH from your allowed IP works normally
- Security checklist is filled out with honest assessments and future module references

## Hints

<details>
<summary>Hint 1: Port scan results aren't what you expected?</summary>

If the online scanner shows port 22 as open, that's expected -- most online scanners use their own IP, which isn't in your UFW allowlist, but the scanner might still detect the port as "filtered" rather than "closed." A "filtered" result means the firewall is silently dropping packets (good -- it means the scanner knows something is there but can't connect). A "closed" result means nothing is listening. Both are fine.

If ports other than 22 are showing as open, check:
- `sudo ufw status verbose` -- is the firewall actually active?
- `sudo docker ps` -- is Docker publishing any ports to 0.0.0.0? Docker can bypass UFW in some configurations.

</details>

<details>
<summary>Hint 2: Can't test from a different IP?</summary>

If you can't easily get a different IP (no mobile data, no friend to help), you can simulate the test:

1. Check your current UFW rules: `sudo ufw status numbered`
2. Temporarily add a rule for "any" on a test port: `sudo ufw allow 9999`
3. Check `sudo ufw status` -- you'll see 9999 is open
4. Delete the test rule: `sudo ufw delete allow 9999`
5. Verify it's gone: `sudo ufw status`

This doesn't test from outside, but it verifies that you understand how to add and remove rules, and that your default deny is working.

</details>

<details>
<summary>Hint 3: Docker and UFW conflict?</summary>

Docker modifies `iptables` directly, which can bypass UFW rules. For our setup, this isn't a problem because:

1. We'll use Cloudflare Tunnel (Module 7) instead of publishing ports
2. In docker-compose, we'll bind ports to `127.0.0.1` only (e.g., `127.0.0.1:3000:3000`) so they're only reachable from localhost

If you're curious, you can test this now:
```bash
# Run a container with a published port
docker run -d --name test-nginx -p 8080:80 nginx

# From the online scanner, check port 8080
# It might show as open even with UFW!

# Clean up
docker stop test-nginx && docker rm test-nginx
```

This is a known issue. The fix is either binding to 127.0.0.1 or not publishing ports at all (which is what we'll do with the tunnel).

</details>

## Solution

<details>
<summary>Click to reveal the full solution walkthrough</summary>

### Part 1: Expected Port Scan Results

With UFW configured as we did in the exercise:

| Port | Expected Result | Why |
|------|----------------|-----|
| 22   | Filtered or Open (depends on scanner IP) | UFW allows SSH from your IP only. Scanner uses a different IP, so it may show filtered. |
| 80   | Closed/Filtered | Default deny incoming blocks this |
| 443  | Closed/Filtered | Default deny incoming blocks this |
| 3000 | Closed/Filtered | Default deny incoming blocks this |
| 8080 | Closed/Filtered | Default deny incoming blocks this |
| 8443 | Closed/Filtered | Default deny incoming blocks this |

"Filtered" means the firewall silently dropped the packet (the scanner gets no response). "Closed" means nothing is listening and the OS sent a rejection. Both are acceptable.

### Part 2: SSH Restriction Test

- **From non-allowed IP:** Connection should hang (timeout) or be refused. UFW silently drops packets from non-allowed IPs, so most clients will just hang until timeout.
- **From allowed IP:** Normal SSH login works.

If you get locked out, use Lightsail's browser-based SSH console:
1. Log into AWS Console
2. Go to Lightsail
3. Click your instance
4. Click "Connect using SSH" (browser-based)
5. Fix the UFW rule: `sudo ufw allow from NEW_IP to any port 22`

### Part 3: Security Audit (Expected State After Module 5)

| Checklist Item | Status | Notes |
|---------------|--------|-------|
| UFW enabled, only SSH from your IP | Done | Completed in exercise |
| No ports 80/443 open | Done | Default deny handles this |
| Cloudflare Tunnel running | Not yet | Module 7 |
| API keys not in plain .env files | Not yet | Module 6 -- risk: anyone with server access can read them |
| Docker Secrets implemented | Not yet | Module 6 |
| Sensitive files chmod 600 | Done (partially) | SSH keys done; secrets files are future |
| No secrets in git | Done | Nothing committed yet |
| Non-root user | Done | Module 3 |
| Phone allowlist | Not yet | Module 8 -- risk: anyone with your bot's number can use it |
| GitHub tokens scoped | Not yet | Module 12 |
| Gmail readonly | Not yet | Module 12 |
| Webhook signature validation | Not yet | Module 8 -- risk: fake webhook requests could trigger the bot |
| Auto-updates enabled | Done | Completed in exercise |
| Health monitoring | Not yet | Module 10 -- risk: won't know if server is compromised or down |
| Alert notifications | Not yet | Module 10 |
| Kill switch | Not yet | Module 11 -- risk: can't stop a runaway bot from phone |
| Kill + revive tested | Not yet | Module 11 |
| Escalation playbook saved | Not yet | Module 11 |

The honest truth: after Module 5, you've addressed the "open ports" leg solidly. The "exposed secrets" and "no monitoring" legs are still open. You know this, you understand the risk, and you have a plan. That's the point of this module -- the awareness and the checklist that drives you to complete the rest.

</details>

### Trade-offs

The approach we took -- UFW with IP-restricted SSH -- is simple and effective, but it has trade-offs:

- **Dynamic IPs can lock you out.** If your ISP changes your IP (common on residential connections), you lose SSH access until you use the web console to update the rule. Alternative: allow SSH from any IP and rely on SSH key authentication only. Less restrictive, but SSH keys are strong.
- **UFW and Docker can conflict.** Docker modifies iptables directly, which can bypass UFW. For our setup with Cloudflare Tunnel, this is fine because we won't publish ports. But if you ever run Docker outside this course, be aware of this interaction.
- **We're not using fail2ban.** Tools like fail2ban automatically ban IPs after failed login attempts. With IP-restricted SSH, this is less necessary, but it's a nice additional layer. If you open SSH to all IPs, consider adding it.
- **No intrusion detection system.** Tools like AIDE or OSSEC monitor filesystem changes and detect tampering. For a personal project, this is overkill. For production, it's worth considering.

Security is always a tradeoff between protection and convenience. The setup we chose prioritizes simplicity and strong defaults. As your needs grow, you can add layers.

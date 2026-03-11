# Challenge 3: Secure Your SSH

## The Scenario

Your VPS is online. Bots are already probing it -- trying default passwords, scanning common ports, looking for easy targets. Right now, your SSH setup works, but it's using default settings that make you a bigger target than necessary. Let's fix that.

Your mission: harden your SSH configuration and set up a shortcut so connecting to your server is as easy as typing `ssh openclaw`.

---

## Task 1: Disable Password Authentication

Right now, your server *might* still accept password logins even though you're using keys. That means bots can keep guessing passwords until they get lucky. Let's slam that door shut.

**What to do:**

1. SSH into your server
2. Edit `/etc/ssh/sshd_config` (the SSH server configuration file)
3. Find the `PasswordAuthentication` setting and set it to `no`
4. Find `ChallengeResponseAuthentication` and set it to `no` (if it exists)
5. Restart the SSH service so the changes take effect
6. **Test from a new terminal window before closing your current session** -- if you messed something up, you need your existing connection to fix it

**Success criteria:**
- You can still connect using your SSH key
- Password authentication is disabled (if someone tries `ssh ubuntu@YOUR_IP` without a key, they get rejected)

---

## Task 2: Set Up an SSH Config Shortcut (Local Machine)

Typing `ssh -i ~/.ssh/openclaw ubuntu@123.45.67.89` every time is tedious. SSH has a built-in way to create shortcuts using a config file on your local machine.

**What to do:**

1. On your **local machine**, create or edit `~/.ssh/config`
2. Add a host entry so that `ssh openclaw` connects to your VPS automatically
3. The config should specify: the hostname (IP), user, and identity file
4. Set proper permissions on the config file
5. Test it -- just type `ssh openclaw` and you should be on your server

**A starter template is provided in `starter/ssh-config-template`.** Copy and customize it.

**Success criteria:**
- Typing `ssh openclaw` in your local terminal connects you to your VPS
- No need to remember the IP, username, or key path

---

## Task 3 (Bonus): Change the SSH Port

This is optional but educational. The default SSH port is 22. Every bot on the internet knows this. Changing it to something non-standard (like 2222 or 41022) won't stop a determined attacker, but it dramatically reduces the noise from automated scanners.

**What to do:**

1. Edit `/etc/ssh/sshd_config` on the server
2. Change the `Port` setting from `22` to something in the range 1024-65535
3. Update your firewall (if configured) to allow the new port
4. Restart SSH
5. Update your local SSH config to include the new port
6. Test the connection

**Warning:** If you change the port and lock yourself out, you'll need to use the Lightsail browser console to fix it. Only attempt this if you're comfortable with that safety net.

**Success criteria:**
- SSH connects on the new port
- Port 22 no longer accepts connections
- Your `ssh openclaw` shortcut still works (because you updated the config)

---

## Hints

<details>
<summary>Hint 1: Which file and what tool?</summary>

On the server, use `sudo nano /etc/ssh/sshd_config` to edit the SSH configuration. Look for lines starting with `PasswordAuthentication` -- they might be commented out (starting with `#`). Remove the `#` and set the value to `no`.

On your local machine, the SSH config lives at `~/.ssh/config`. It doesn't exist by default -- you create it. Set its permissions to `chmod 644 ~/.ssh/config`.

</details>

<details>
<summary>Hint 2: The sshd_config changes</summary>

In `/etc/ssh/sshd_config`, find and set these lines (remove the `#` if they're commented):

```
PasswordAuthentication no
ChallengeResponseAuthentication no
```

After saving, restart SSH with: `sudo systemctl restart ssh`

**Critical:** Test from a NEW terminal window before closing your current session. Open a new tab, try to connect. If it works, you're safe to close the old one.

</details>

<details>
<summary>Hint 3: SSH config format</summary>

The `~/.ssh/config` file uses this format:

```
Host openclaw
    HostName YOUR_VPS_IP
    User ubuntu
    IdentityFile ~/.ssh/openclaw
    Port 22
```

Replace `YOUR_VPS_IP` with your actual IP. If you changed the port in Task 3, update `Port` accordingly.

After creating the file: `chmod 644 ~/.ssh/config`

Then just: `ssh openclaw`

</details>

---

## Solution

<details>
<summary>Click to reveal the full solution</summary>

### Task 1: Disable Password Authentication

```bash
# SSH into your server
ssh -i ~/.ssh/openclaw ubuntu@YOUR_VPS_IP

# Edit the SSH config
sudo nano /etc/ssh/sshd_config
```

Find and change (or add) these lines:

```
PasswordAuthentication no
ChallengeResponseAuthentication no
```

Save (`Ctrl+O`, Enter) and exit (`Ctrl+X`).

```bash
# Restart SSH to apply changes
sudo systemctl restart ssh

# Check that SSH is still running
sudo systemctl status ssh
```

**Now open a new terminal window and test:**

```bash
ssh -i ~/.ssh/openclaw ubuntu@YOUR_VPS_IP
```

If that works, you're good. If not, go back to your original terminal (which is still connected) and fix the config.

### Task 2: SSH Config Shortcut

On your **local machine**:

```bash
# Create the SSH config file (or edit it if it exists)
nano ~/.ssh/config
```

Add this block:

```
Host openclaw
    HostName YOUR_VPS_IP
    User ubuntu
    IdentityFile ~/.ssh/openclaw
    Port 22
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

The last two lines are a bonus -- they send a keepalive signal every 60 seconds so your SSH connection doesn't drop if you step away for a few minutes.

Save and exit, then set permissions:

```bash
chmod 644 ~/.ssh/config
```

Test it:

```bash
ssh openclaw
```

You should land on your server without specifying any other details.

### Task 3 (Bonus): Change SSH Port

On the server:

```bash
sudo nano /etc/ssh/sshd_config
```

Find the `Port` line (usually `#Port 22`) and change it to:

```
Port 41022
```

Save and exit. Before restarting SSH, make sure the new port isn't blocked. If you have UFW running:

```bash
sudo ufw allow 41022/tcp
```

Now restart:

```bash
sudo systemctl restart ssh
```

**Test immediately from a new terminal** (keep your current session open):

```bash
ssh -i ~/.ssh/openclaw -p 41022 ubuntu@YOUR_VPS_IP
```

If that works, update your local `~/.ssh/config`:

```
Host openclaw
    HostName YOUR_VPS_IP
    User ubuntu
    IdentityFile ~/.ssh/openclaw
    Port 41022
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

Now `ssh openclaw` uses the new port automatically.

Optionally, close the old port:

```bash
sudo ufw deny 22/tcp
```

### Why These Changes Matter

- **Disabling password auth** eliminates brute-force attacks entirely. Bots can't guess a 256-bit key.
- **SSH config shortcuts** save you time and reduce errors (no more mistyping IPs).
- **Changing the port** is "security through obscurity" -- it doesn't make you *secure* against targeted attacks, but it eliminates 99% of automated noise. Your `auth.log` will go from hundreds of failed attempts per day to nearly zero.

### Trade-offs

The main risk of all three changes is **locking yourself out**. That's why we:
1. Always test from a new terminal before closing the working session
2. Keep the Lightsail browser console as a backup
3. Make changes incrementally (one thing at a time, test, then the next)

If you ever *do* lock yourself out, the Lightsail browser console bypasses SSH entirely -- you can log in and fix your config from there.

</details>

# Exercise: Lock Down Your Server

## What We're Doing

We're going to configure a firewall on your VPS, enable automatic security updates, verify your non-root user setup, and check file permissions on sensitive files. By the end of this exercise, your server will be significantly harder to attack than it was 30 minutes ago.

## Prerequisites

- SSH access to your VPS as the `openclaw` user (from Module 3)
- Your local machine's public IP address (we'll show you how to find it)
- About 30 minutes

## Part 1: Find Your Public IP Address

Before we configure the firewall, you need to know your current IP address. This is the IP the firewall will allow SSH from.

**1.** On your **local machine** (not the VPS), run:

```bash
curl -4 ifconfig.me
```

This returns your public IP address. Write it down -- you'll need it in a moment.

> **Pro tip:** If your ISP gives you a dynamic IP (most residential connections do), your IP might change periodically. If you get locked out after an IP change, you can use your VPS provider's web console (Lightsail browser-based SSH) to update the firewall rule. We'll cover this in the troubleshooting section.

**2.** Now SSH into your VPS:

```bash
ssh openclaw@YOUR_VPS_IP
```

## Part 2: Configure UFW Firewall

**3.** First, let's check if UFW is already installed (it comes pre-installed on most Ubuntu versions):

```bash
sudo ufw status
```

You should see `Status: inactive`. If UFW isn't installed:

```bash
sudo apt update && sudo apt install ufw -y
```

**4.** Before we enable the firewall, let's think about what we want:

- **Block all incoming traffic** by default (nobody gets in unless we say so)
- **Allow all outgoing traffic** (our server needs to reach the internet -- API calls, tunnel connections, package updates)
- **Allow SSH from our IP only** (so we don't lock ourselves out)

Before running the next command, think: **what would happen if we enabled the firewall right now without adding the SSH rule first?**

Think about it. Seriously.

...

We'd lock ourselves out. The firewall would block all incoming traffic, including our SSH connection. We'd have to use the Lightsail web console to fix it. Let's not do that.

**5.** Set the defaults:

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
```

**6.** Add the SSH rule. Replace `YOUR_IP` with the IP address from step 1:

```bash
sudo ufw allow from YOUR_IP to any port 22
```

> **What if you have a dynamic IP?** You have two options. Option A: Allow SSH from any IP (`sudo ufw allow 22`) -- less secure but you won't get locked out. SSH key authentication (which you set up in Module 3) still protects you. Option B: Use the IP-restricted rule and update it when your IP changes. We recommend option B but won't judge you for option A.

**7.** Enable the firewall:

```bash
sudo ufw enable
```

It will warn you that this may disrupt existing SSH connections. Since we just added our SSH rule, type `y` to proceed.

**8.** Verify the configuration:

```bash
sudo ufw status verbose
```

You should see something like:

```
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)
New profiles: skip

To                         Action      From
--                         ------      ----
22                         ALLOW IN    YOUR_IP
```

That's it. Your server just became invisible to port scanners on every port except SSH, and SSH only responds to your IP.

**9.** Let's verify from the server side. Check what ports are listening:

```bash
sudo ss -tlnp
```

This shows all TCP ports that are listening. You'll probably see ports like 22 (SSH) and maybe Docker ports. The firewall doesn't stop services from *listening* -- it stops external traffic from *reaching* them. Think of it as a wall around the building. The doors inside still exist, but nobody outside can get to them.

## Part 3: Enable Automatic Security Updates

**10.** Install the unattended-upgrades package:

```bash
sudo apt install unattended-upgrades -y
```

**11.** Enable automatic security updates:

```bash
sudo dpkg-reconfigure -plow unattended-upgrades
```

When prompted, select **Yes**.

**12.** Verify it's configured:

```bash
cat /etc/apt/apt.conf.d/20auto-upgrades
```

You should see:

```
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
```

This means the system checks for updates daily and installs security patches automatically. One less thing to remember.

## Part 4: Verify Your User Setup

Let's make sure the non-root setup from Module 3 is solid.

**13.** Confirm you're logged in as `openclaw` (not root):

```bash
whoami
```

Should output `openclaw`. If it says `root`, switch: `su - openclaw`

**14.** Verify `openclaw` is in the `docker` group:

```bash
groups
```

You should see `docker` in the list. This means the `openclaw` user can manage containers without `sudo`.

**15.** Verify you can use sudo when needed (for system administration):

```bash
sudo whoami
```

Should output `root`. This confirms `openclaw` has sudo access for administrative tasks but doesn't run as root by default.

## Part 5: Check File Permissions on Sensitive Files

**16.** Let's check permissions on the SSH directory:

```bash
ls -la ~/.ssh/
```

The `.ssh` directory should be `700` (drwx------) and `authorized_keys` should be `600` (-rw-------). If they're not:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

**17.** If you have any config files or future `.env` files, the same principle applies. Check your home directory:

```bash
ls -la ~/
```

Look for any files that might contain sensitive data. They should not be world-readable (no `r` in the last three permission characters).

> **Pro tip:** The command `find ~ -perm -o=r -type f` finds all files in your home directory that are readable by "others" (anyone on the system). Ideally this list is very short.

## Part 6: "What Would Happen If..." Scenarios

Let's test your understanding. For each scenario, predict what would happen, then we'll verify.

**18.** What would happen if someone from a random IP tried to SSH into your server?

Predict first, then test by looking at the UFW rules:

```bash
sudo ufw status numbered
```

Answer: The connection would be refused (or time out). The firewall only allows SSH from your specific IP address. The attacker wouldn't even get a "connection refused" message on most configurations -- the packet just gets silently dropped, so their scanner thinks no server exists at that IP.

**19.** What would happen if you ran a container with `-p 3000:3000` right now?

Predict, then think through the layers:

Answer: The container would listen on port 3000 internally, and Docker would set up port forwarding. However, the UFW firewall blocks all incoming traffic except SSH from your IP. So no one on the internet could reach port 3000 -- it's blocked at the firewall level before it ever reaches Docker.

**Important caveat:** Docker can sometimes bypass UFW by modifying iptables directly. This is a known gotcha. For our setup with Cloudflare Tunnel (Module 7), this doesn't matter because we won't be publishing ports to the host at all -- containers will communicate on internal Docker networks only. But it's worth knowing that Docker and UFW don't always play nice together.

**20.** What would happen if you forgot to renew your Claude API key and someone found the old one?

Answer: Expired/revoked keys don't work. This is why token rotation and expiration dates are good practices. An attacker who finds an old, revoked key gets nothing. We'll set up key rotation reminders in Module 12.

## What Just Happened?

Let's take stock of what you just did:

- **Firewall configured:** All incoming traffic blocked except SSH from your IP. Your server is now invisible to port scanners.
- **Auto-updates enabled:** Security patches install automatically. Known vulnerabilities get closed without you lifting a finger.
- **User setup verified:** You're running as a non-root user. If something goes wrong, the damage is contained.
- **Permissions checked:** Sensitive files are readable only by their owner.

That's two legs of the lethal trifecta addressed in the "awareness" column (secrets and monitoring are coming in Modules 6 and 10), and one leg -- open ports -- actively hardened right now.

Check off these items on your security checklist (the one in `starter/security-checklist.md`):

- [x] UFW enabled, only SSH from your IP
- [x] No ports 80/443 open
- [x] Automatic OS security updates enabled
- [x] Running as dedicated `openclaw` user, not root

## Try This (Optional Experiments)

If you want to dig deeper:

1. **Check your SSH auth log** to see how many bots have already tried to log in:
   ```bash
   sudo grep "Failed password" /var/log/auth.log | wc -l
   ```
   The number might surprise you. (If you set up SSH key auth in Module 3 and disabled password auth, these attempts all failed -- but they show you how active the scanning is.)

2. **Look at UFW logs** to see blocked connection attempts:
   ```bash
   sudo grep "UFW BLOCK" /var/log/syslog | tail -20
   ```

3. **Test the firewall from outside**: From a different network (your phone's mobile data, for example), try to ping your server:
   ```bash
   ping YOUR_VPS_IP
   ```
   Depending on your UFW config, this may or may not respond. Try to SSH from that IP -- it should be refused.

4. **Check what's actually listening** on your server and think about whether each service needs to be:
   ```bash
   sudo ss -tlnp
   ```
   For each listening port, ask: "Does this need to be reachable from the internet?" For everything Docker-related, the answer is almost always "no -- it'll go through the tunnel."

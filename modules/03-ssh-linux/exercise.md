# Exercise 3: Remote Control -- SSH and Linux Basics

## What We're Doing

You're going to generate your own SSH key, connect to your VPS, explore the Linux filesystem, create the `openclaw` user, install a package, check on a service, and create files with proper permissions. By the end, you'll be comfortable navigating and managing your server.

## Before You Start

- Your Lightsail instance is running and you have its static IP address (from Module 2)
- You have the SSH key you downloaded from Lightsail (usually a `.pem` file)
- You have a terminal open on your local machine

---

## Part 1: Generate Your Own SSH Key

The Lightsail-generated key works, but let's create our own -- it's cleaner and more portable.

### Step 1: Generate a key pair

Run this on your **local machine** (not the server):

```bash
ssh-keygen -t ed25519 -C "openclaw-vps" -f ~/.ssh/openclaw
```

Let's break that down:
- `-t ed25519` -- the encryption algorithm. Ed25519 is modern, fast, and secure.
- `-C "openclaw-vps"` -- a comment/label so you remember what this key is for
- `-f ~/.ssh/openclaw` -- where to save the key files

When it asks for a passphrase, you can either:
- **Set one** (more secure -- even if someone steals your key file, they need the passphrase)
- **Leave it blank** (more convenient -- no passphrase prompt every time you connect)

For this course, either is fine. If you're security-minded, set one.

### Step 2: Verify the key files were created

```bash
ls -la ~/.ssh/openclaw*
```

You should see two files:
- `~/.ssh/openclaw` -- your **private key** (the key). Never share this.
- `~/.ssh/openclaw.pub` -- your **public key** (the padlock). This goes on the server.

### Step 3: Check the private key permissions

```bash
ls -la ~/.ssh/openclaw
```

The permissions should show `-rw-------` (which is `600`). If they don't:

```bash
chmod 600 ~/.ssh/openclaw
```

SSH is strict about this -- it will **refuse to use a private key** if other users can read it. This is a security feature, not a bug.

> **Pro tip:** This is one of the most common SSH errors beginners hit: "Permissions 0644 for '/home/you/.ssh/openclaw' are too open." Now you know the fix: `chmod 600`.

---

## Part 2: Connect to Your VPS

### Step 4: SSH in using the Lightsail key

First, let's connect with the key you already have from Module 2:

```bash
ssh -i ~/path/to/LightsailDefaultKey.pem ubuntu@YOUR_VPS_IP
```

Replace `~/path/to/LightsailDefaultKey.pem` with the actual path to your Lightsail key, and `YOUR_VPS_IP` with your static IP.

**Note:** Lightsail Ubuntu instances use the username `ubuntu`, not `root`. The `ubuntu` user has `sudo` privileges, so it can do everything root can.

The first time you connect, you'll see a message like:

```
The authenticity of host '123.45.67.89 (123.45.67.89)' can't be established.
ED25519 key fingerprint is SHA256:abc123...
Are you sure you want to continue connecting (yes/no)?
```

Type `yes`. This is SSH asking "I've never seen this server before -- do you trust it?" The fingerprint gets saved so it won't ask again.

### Step 5: Confirm you're on the server

Your prompt should have changed. Run:

```bash
hostname
```

This should print your server's hostname (something like `ip-172-26-1-42`), not your laptop's name. You're in.

```bash
whoami
```

This should print `ubuntu`. That's the user you're logged in as.

---

## Part 3: Explore the Filesystem

### Step 6: Look around

**Before running each command, predict what you'll see.** Seriously -- predictions make the learning stick.

```bash
ls /
```

This lists everything in the root directory. You should see `home`, `etc`, `var`, `root`, `tmp`, `usr`, and others from the lesson.

```bash
ls /home
```

You should see `ubuntu` -- that's the default user's home directory.

```bash
ls /etc | head -20
```

A taste of the config files. There are a *lot* of them. Don't worry, you'll only ever touch a few.

```bash
ls -la /root
```

This will probably say "Permission denied" -- and that's correct! You're logged in as `ubuntu`, not `root`. The `/root` directory is root's home, and regular users can't peek inside.

Try it with sudo:

```bash
sudo ls -la /root
```

Now it works. `sudo` gives you temporary root powers for just that one command.

### Step 7: Check disk space and memory

```bash
df -h
```

This shows disk usage in human-readable format. Your Lightsail instance probably has 20-40 GB.

```bash
free -h
```

This shows memory (RAM). You'll see total, used, and available.

> **Pro tip:** These two commands (`df -h` and `free -h`) are the quickest way to check if your server is running low on resources. You'll use them often.

---

## Part 4: Create the OpenClaw User

### Step 8: Create the dedicated user

```bash
sudo adduser --system --group --home /home/openclaw --shell /bin/bash openclaw
```

You should see output like:

```
Adding system user `openclaw' (UID 998) ...
Adding new group `openclaw' (GID 998) ...
Adding new user `openclaw' (UID 998) with group `openclaw' ...
Creating home directory `/home/openclaw' ...
```

### Step 9: Verify the user exists

```bash
id openclaw
```

This should show the user ID, group ID, and group memberships. Something like:

```
uid=998(openclaw) gid=998(openclaw) groups=998(openclaw)
```

### Step 10: Set ownership on the home directory

```bash
sudo chown -R openclaw:openclaw /home/openclaw
```

The `-R` flag means recursive -- set ownership on the directory *and everything inside it*.

Verify:

```bash
ls -la /home/
```

You should see `openclaw` listed alongside `ubuntu`, with `openclaw openclaw` as the owner and group.

---

## Part 5: Install a Package

### Step 11: Update the package list and install htop

```bash
sudo apt update
```

Watch it download package lists from Ubuntu's repositories. This takes 10-30 seconds.

Now install `htop` (a beautiful system monitor):

```bash
sudo apt install htop -y
```

The `-y` flag means "yes to all prompts" so you don't have to confirm the installation.

### Step 12: Run htop

```bash
htop
```

You're looking at a real-time view of your server's processes, CPU usage, and memory. This is way more readable than the default `top` command.

Press `q` to exit htop.

---

## Part 6: Check a Service

### Step 13: Check the SSH service status

```bash
sudo systemctl status ssh
```

(On Ubuntu it's `ssh`, not `sshd`.)

You should see a green "active (running)" status and some recent log lines. This is the service that's allowing your current connection -- if it stopped, you'd be locked out.

**Before running the next command, think about this:** What would happen if you ran `sudo systemctl stop ssh` right now?

Answer: you'd kill the SSH service while connected through it. Your current session *might* survive briefly, but you couldn't reconnect. You'd have to use the Lightsail browser console to fix it. Don't run it -- just understand why.

### Step 14: Check what services are running

```bash
systemctl list-units --type=service --state=running
```

This lists all currently running services. You'll see SSH, some system services, and not much else -- your server is pretty minimal right now. That's good. Fewer services = smaller attack surface.

---

## Part 7: File Permissions in Practice

### Step 15: Create a test file and explore permissions

```bash
cd /home/openclaw
sudo touch secret.txt
sudo bash -c 'echo "my-api-key-12345" > secret.txt'
```

Check the current permissions:

```bash
ls -la secret.txt
```

It probably shows `-rw-r--r--` (644) -- owner can read/write, everyone else can read. That's bad for a secret file.

Lock it down:

```bash
sudo chmod 600 secret.txt
```

Check again:

```bash
ls -la secret.txt
```

Now it should show `-rw-------` -- only the owner can read and write. And set the right owner:

```bash
sudo chown openclaw:openclaw secret.txt
```

Now verify:

```bash
ls -la secret.txt
```

You should see `openclaw openclaw` as the owner/group, with `-rw-------` permissions. This file is now readable only by the `openclaw` user.

### Step 16: Test that permissions actually work

Try reading the file as your current user (`ubuntu`):

```bash
cat secret.txt
```

This should say "Permission denied" -- and that's *exactly* what we want. The secret is locked to the `openclaw` user only.

Now try with sudo:

```bash
sudo cat secret.txt
```

This works because sudo gives you root powers, and root can read everything. (This is another reason to limit who has sudo access.)

Clean up:

```bash
sudo rm secret.txt
```

---

## Part 8: Edit a File with nano

### Step 17: Create and edit a file

```bash
sudo -u openclaw nano /home/openclaw/notes.txt
```

The `sudo -u openclaw` part means "run this command as the openclaw user." This way the file will be owned by `openclaw` from the start.

Type a few lines -- anything you want. Maybe:

```
OpenClaw VPS Setup Notes
========================
Server IP: [your IP]
Created openclaw user: done
```

Save with `Ctrl+O`, press Enter to confirm the filename, then exit with `Ctrl+X`.

Verify the file:

```bash
sudo cat /home/openclaw/notes.txt
```

Clean up:

```bash
sudo rm /home/openclaw/notes.txt
```

---

## Part 9: Copy Your New SSH Key to the Server

### Step 18: Add your new public key to the server

Remember the key we generated in Step 1? Let's add it so you can use it to connect.

On **your local machine** (open a new terminal window, or disconnect with `exit` first), display your public key:

```bash
cat ~/.ssh/openclaw.pub
```

Copy the entire output (it starts with `ssh-ed25519` and ends with `openclaw-vps`).

Now SSH back into the server (using the Lightsail key) and add the key:

```bash
sudo mkdir -p /home/ubuntu/.ssh
```

Then add your public key to the authorized_keys file:

```bash
echo "PASTE_YOUR_PUBLIC_KEY_HERE" | sudo tee -a /home/ubuntu/.ssh/authorized_keys
```

Replace `PASTE_YOUR_PUBLIC_KEY_HERE` with the actual key you copied.

### Step 19: Test the new key

Disconnect from the server:

```bash
exit
```

Now reconnect using your new key:

```bash
ssh -i ~/.ssh/openclaw ubuntu@YOUR_VPS_IP
```

If you see the server prompt, it worked. You're now connecting with your own key.

---

## What Just Happened?

Take a breath -- you just did a lot. Here's what you accomplished:

1. **Generated an SSH key pair** -- your own cryptographic identity for this server
2. **Connected via SSH** -- you can now remotely control your VPS from anywhere
3. **Explored the filesystem** -- you know where things live on a Linux server
4. **Created the `openclaw` user** -- a dedicated, limited user for running your AI agent
5. **Installed software with apt** -- you can add tools and packages to the server
6. **Checked services with systemctl** -- you can see what's running and manage background processes
7. **Set file permissions** -- you can protect sensitive files from unauthorized access
8. **Edited files with nano** -- you can modify configuration files directly on the server

These aren't just "Module 3 skills" -- these are fundamental Linux administration skills. Every single thing you did here is something professional DevOps engineers do daily.

---

## Try This (Optional Experiments)

If you've got time and curiosity to spare:

1. **Explore /etc/ssh/sshd_config** -- Run `sudo cat /etc/ssh/sshd_config`. This is the SSH server's configuration file. See if you can spot the settings for password authentication and the port number. (You'll modify this file in the challenge.)

2. **Check login attempts** -- Run `sudo cat /var/log/auth.log | tail -30`. If your server has been online for a while, you might already see failed login attempts from bots. Welcome to the internet.

3. **Create a directory structure** -- Try creating `/home/openclaw/config` and `/home/openclaw/data` directories with proper ownership. These are directories we'll use later in the course.

```bash
sudo mkdir -p /home/openclaw/{config,data}
sudo chown -R openclaw:openclaw /home/openclaw/
sudo chmod 700 /home/openclaw/config /home/openclaw/data
```

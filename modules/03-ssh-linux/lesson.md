# Lesson 3: Remote Control -- SSH and Linux Basics

## The Locked Room Problem

Here's the situation: you just rented a computer. It's powerful, it's running 24/7, and it has a fresh install of Ubuntu Linux. But it's sitting in an Amazon data center, probably in Virginia or Frankfurt, and you can't exactly walk up to it with a keyboard.

So how do you type commands on a computer you can't touch?

The answer is SSH -- **Secure Shell** -- and it's one of the most important tools you'll ever learn. Every server in the world is managed through SSH. Every DevOps engineer uses it daily. And once you understand how it works, it'll feel as natural as opening a terminal on your own machine.

---

## SSH: The Lock and Key

SSH uses something called **public-key cryptography**, which sounds intimidating but is actually a really elegant idea. Here's the analogy:

Imagine you have a special padlock and a matching key. The padlock is unusual -- once you snap it shut, *only* your specific key can open it. You can make copies of the padlock and hand them out to anyone. Put one on your storage unit, give one to your server, nail one to a tree -- it doesn't matter. The padlock is useless for *opening* anything. Only the key can do that, and the key never leaves your pocket.

That's exactly how SSH keys work:

- **Public key** (the padlock) -- goes on the server. You can share it freely. It can only *lock* things (encrypt), not unlock them.
- **Private key** (the key) -- stays on *your* machine. Never leaves. Never shared. Never emailed. This is what proves you are you.

When you connect to your server, here's what happens behind the scenes:

1. Your computer says "Hey, I'd like to connect"
2. The server sends a random challenge, encrypted with your public key (the padlock)
3. Your computer decrypts it with your private key (because only you have it)
4. The server goes "Yep, that's correct -- you must have the real key. Come on in."

This all happens in milliseconds. You just see the terminal prompt change.

### Why Not Just Use Passwords?

Fair question. Passwords *work* for SSH, but they're a terrible idea for servers:

- **Brute force attacks** -- Automated bots scan the internet 24/7, trying common username/password combos on every server they find. Your VPS will start getting these attempts within *minutes* of going online. Not an exaggeration.
- **Passwords can be guessed** -- Even "strong" passwords are weaker than a 4096-bit SSH key. A key is essentially a password that's thousands of characters long and randomly generated.
- **Passwords can be phished** -- Someone tricks you into typing your password on a fake site. Your private key never gets typed anywhere.

> **The bigger picture:** The Lightsail instance you created in Module 2 already has SSH key authentication set up -- that's the key pair you downloaded (or that Lightsail generated for you). What we're doing in this module is understanding how that works and setting up our *own* keys for a cleaner workflow.

---

## Connecting for the First Time

The basic SSH command looks like this:

```bash
ssh -i ~/.ssh/your-key-file root@your-server-ip
```

Let's break that down:

- `ssh` -- the command itself
- `-i ~/.ssh/your-key-file` -- "use this specific private key file" (the `-i` stands for "identity")
- `root` -- the username you're logging in as (root = the admin account)
- `@` -- separator between username and server
- `your-server-ip` -- the static IP from Module 2

Once connected, your terminal prompt changes. You're no longer running commands on your laptop -- you're running them *on the server*. Everything you type happens on that remote machine in the data center.

> **Pro tip:** To disconnect from SSH, type `exit` or press `Ctrl+D`. Don't just close the terminal window -- that works too, but `exit` is cleaner.

---

## The Linux Filesystem: Where Things Live

Your server runs Ubuntu Linux, and Linux organizes files differently than macOS or Windows. There's no `C:\` drive, no "Applications" folder. Everything starts from a single root directory: `/` (just a forward slash).

Here's the tour of the directories you'll actually care about:

| Directory | What's in it | Why you care |
|-----------|-------------|--------------|
| `/home` | User home directories | Your `openclaw` user's files live in `/home/openclaw` |
| `/root` | Root user's home directory | Where you land when you SSH in as root |
| `/etc` | Configuration files | SSH config, system settings, service configs |
| `/var` | Variable data (logs, databases) | Docker stores its data here, logs live here |
| `/tmp` | Temporary files | Cleared on reboot. Safe scratch space |
| `/usr` | User programs and libraries | Where installed software binaries end up |
| `/opt` | Optional third-party software | Sometimes software installs itself here |

The ones in bold you'll touch in this course. The rest? Good to know they exist, but you won't be digging around in them.

### Getting Around

If you can `cd` and `ls` on your local machine, you already know the basics:

```bash
pwd              # Print Working Directory -- where am I?
ls               # List files in current directory
ls -la           # List ALL files (including hidden), with details
cd /etc          # Change to the /etc directory
cd ~             # Go to your home directory (shortcut for /home/yourusername)
cd ..            # Go up one directory
```

Nothing exotic here. The main difference from your laptop is that *you're navigating someone else's computer* -- and everything you do has real consequences on a live server.

---

## Users and Permissions: Why Root Is Dangerous

When you first SSH into your Lightsail instance, you're logged in as `root`. Root is the superuser -- it can read every file, kill every process, delete the entire filesystem. Root is god mode.

And that's exactly the problem.

If you run OpenClaw as root and something goes wrong -- maybe a bug, maybe a cleverly crafted prompt injection -- the attacker has **full control of your entire server**. They can read your secrets, install malware, use your server to attack other servers, mine cryptocurrency... the works.

The fix is simple: **create a regular user and run everything as that user.**

A regular user can only:
- Read/write files they own (or that are explicitly shared with them)
- Run programs in their own space
- Do almost nothing to the rest of the system

If an attacker compromises a regular user, they're stuck in a sandbox. They can mess up that user's files, but the system itself is protected.

### The `openclaw` User

We're going to create a dedicated user just for running OpenClaw:

```bash
adduser --system --group --home /home/openclaw --shell /bin/bash openclaw
```

Let's unpack those flags:
- `--system` -- creates a "system" user (slightly different from a normal user; no password login, lower user ID)
- `--group` -- also create a group with the same name
- `--home /home/openclaw` -- set the home directory
- `--shell /bin/bash` -- give it a real shell (so we can switch to this user and run commands)
- `openclaw` -- the username

> **The bigger picture:** This pattern -- "create a dedicated user per application" -- is a security best practice called the **principle of least privilege**. You'll hear this phrase a lot in Module 5 (Security Fundamentals). The idea: give every piece of software exactly the permissions it needs and not a single bit more.

### File Permissions: The Number System

Linux permissions look scary at first but follow a simple pattern. Every file has three permission groups:

1. **Owner** -- the user who owns the file
2. **Group** -- users in the file's group
3. **Others** -- everyone else

Each group gets three permissions:
- **r** (read) = 4
- **w** (write) = 2
- **x** (execute) = 1

You add them up: read + write = 6, read + write + execute = 7, read only = 4.

The two patterns you'll use constantly in this course:

```bash
chmod 600 secret-file     # Owner can read/write. Nobody else can do anything.
chmod 700 secret-dir      # Owner can read/write/enter. Nobody else can do anything.
```

And to change *who* owns a file:

```bash
chown openclaw:openclaw /home/openclaw/   # The openclaw user and group now own this
```

That colon syntax is `user:group`. Most of the time you'll set them to the same thing.

> **Pro tip:** If you see a permissions string like `-rw-------`, that's 600. If it's `drwx------`, that's 700 (the `d` means it's a directory). Once you know the number system, you can read these at a glance.

---

## Package Management: `apt`

Ubuntu uses `apt` (Advanced Package Tool) to install software. Think of it as an app store for the command line -- except everything is free and you don't need to create an account.

Two commands you need:

```bash
sudo apt update            # Refresh the list of available packages (like refreshing the app store)
sudo apt install htop      # Install a package (htop = a nice system monitor)
```

**Always run `apt update` before `apt install`**. The package list on your server gets stale. If you try to install something without updating first, apt might look for an old version that no longer exists and throw an error.

The `sudo` at the beginning means "run this as root." Even when you're logged in as a regular user, `sudo` lets you temporarily escalate to root privileges for a single command. It's like asking for the manager's key to unlock the supply closet -- you use it for that one task, then hand it back.

> **Pro tip:** You can install multiple packages at once: `sudo apt install htop curl wget git`. Saves time.

---

## Services and systemd: Things That Run in the Background

Some programs on your server aren't things you run once and they exit -- they're **services** that run continuously in the background. Your SSH server is one of them (otherwise you couldn't connect). Later, Docker will be another.

Linux uses `systemd` to manage these services, and you control it with the `systemctl` command:

```bash
sudo systemctl status sshd     # Is SSH running? What's its status?
sudo systemctl start sshd      # Start the SSH service
sudo systemctl stop sshd       # Stop it (don't do this while you're connected via SSH!)
sudo systemctl restart sshd    # Stop then start (useful after config changes)
sudo systemctl enable sshd     # Start automatically when the server boots
sudo systemctl disable sshd    # Don't start on boot
```

The one that trips people up: **`enable` doesn't start the service right now**. It just sets it to start automatically on the next boot. If you want it running *now* and on every future boot:

```bash
sudo systemctl enable --now sshd    # Enable AND start immediately
```

> **Pro tip:** `systemctl status` is your best friend for debugging. If a service isn't working, `status` will show you the last few log lines and whether it's running, stopped, or crashed.

---

## Editing Files with nano

At some point you'll need to edit a config file on the server. You don't have VS Code up there (well, you could, but that's overkill). The simplest terminal text editor is `nano`:

```bash
nano /path/to/file
```

The key shortcuts are shown at the bottom of the screen (`^` means Ctrl):

- `Ctrl+O` -- save (write **O**ut)
- `Ctrl+X` -- exit
- `Ctrl+K` -- cut a line
- `Ctrl+U` -- paste a line
- `Ctrl+W` -- search (**W**here is...)

That's it. Nano isn't fancy, and that's exactly the point. You don't need fancy to change one line in a config file.

> **Pro tip:** If you ever accidentally open `vim` instead of `nano` and can't figure out how to exit -- type `:q!` and press Enter. This is not a joke; "how to exit vim" is one of the most viewed Stack Overflow questions of all time.

---

## Putting It All Together

Here's what your workflow looks like after this module:

1. Open your terminal locally
2. `ssh root@your-vps-ip` -- connect to the server
3. Navigate around, install packages, create users, edit configs
4. `exit` -- disconnect

You now have remote control of a Linux server. That might not sound flashy, but it's genuinely one of the most powerful skills in all of tech. Every web app you use, every API you've called, every cloud service you've relied on -- they all run on servers managed by people doing exactly what you just learned.

Next up: Docker. You're about to learn how to run software in containers, and you'll use SSH and everything from this module to get it set up.

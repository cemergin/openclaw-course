# Exercise: Set Up the Config-as-Code Deploy Pipeline

## What We're Doing

You're going to take the config-as-code repo you built in Module 3, push it to a private GitHub repo, add a GitHub Actions workflow that automatically deploys to your VPS, set up a deploy key so your server can pull the repo, configure GitHub Secrets, and verify the whole pipeline works end-to-end. By the end, you'll push a change to SOUL.md and watch it land on your server automatically.

## Prerequisites

- A working VPS from Module 4 (SSH access as `deploy`, Node.js, OpenClaw, and Docker installed)
- The config-as-code repo from Module 3 (with `config/openclaw.json`, `workspace/SOUL.md`, `docker-compose.yml`)
- A GitHub account
- Git installed on your local machine
- About 20-30 minutes

---

## Step 1: Push Your Config Repo to GitHub

If you haven't already pushed your Module 3 repo to GitHub:

1. Go to [github.com/new](https://github.com/new)
2. **Repository name:** `openclaw-deploy` (or your preference)
3. **Visibility:** Private (important!)
4. **Do NOT** initialize with README, .gitignore, or license -- your repo already has files
5. Click **Create repository**

On your **local machine**, in your config-as-code repo directory:

```bash
cd ~/openclaw-deploy    # or wherever your Module 3 repo lives
git remote add origin git@github.com:YOURUSERNAME/openclaw-deploy.git
git branch -M main
git push -u origin main
```

Replace `YOURUSERNAME` with your actual GitHub username.

> **Already pushed?** Skip to Step 2. The repo from Module 3 is the deployment repo -- no need to create a new one.

---

## Step 2: Create the GitHub Actions Workflow

Create the workflow directory and file:

```bash
mkdir -p .github/workflows
```

Now create the deploy workflow. A starter template is in `starter/deploy.yml` -- copy it or create from scratch:

```bash
cat > .github/workflows/deploy.yml << 'EOF'
name: Deploy to VPS

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Deploy to VPS via SSH
        uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.VPS_HOST }}
          username: ${{ secrets.VPS_USER }}
          key: ${{ secrets.VPS_SSH_KEY }}
          script: |
            set -e

            # --- Step 1: Clone or pull the repo ---
            if [ ! -d ~/openclaw/.git ]; then
              cd ~
              rm -rf openclaw
              git clone ${{ github.event.repository.ssh_url }} openclaw
            else
              cd ~/openclaw
              git pull origin main
            fi

            # --- Step 2: Copy OpenClaw config ---
            cp ~/openclaw/config/openclaw.json ~/.openclaw/openclaw.json

            # --- Step 3: Copy workspace files ---
            mkdir -p ~/.openclaw/workspace
            cp -r ~/openclaw/workspace/* ~/.openclaw/workspace/

            # --- Step 4: Update OpenClaw if needed ---
            sudo npm update -g openclaw

            # --- Step 5: Restart OpenClaw gateway ---
            openclaw gateway restart || openclaw gateway start

            # --- Step 6: Start support services ---
            cd ~/openclaw
            docker compose up -d

            echo "Deploy complete!"
EOF
```

---

## Step 3: Set Up a Deploy Key on Your VPS

Your VPS needs read access to the private repo. We'll use an SSH deploy key.

**On your VPS** (SSH in as `deploy`):

```bash
ssh openclaw
```

Generate a deploy key:

```bash
ssh-keygen -t ed25519 -C "openclaw-deploy-key" -f ~/.ssh/github_deploy -N ""
```

Display the public key:

```bash
cat ~/.ssh/github_deploy.pub
```

Copy the output.

**On GitHub**, go to your repo > Settings > Deploy keys > Add deploy key:
- **Title:** `VPS Deploy Key`
- **Key:** Paste the public key
- **Allow write access:** Leave unchecked (read-only is all we need)

**Back on your VPS**, configure git to use this key for GitHub:

```bash
cat > ~/.ssh/config << 'EOF'
Host github.com
    IdentityFile ~/.ssh/github_deploy
    StrictHostKeyChecking accept-new
EOF

chmod 600 ~/.ssh/config
```

Test the connection:

```bash
ssh -T git@github.com
```

You should see a message like "Hi username/openclaw-deploy! You've successfully authenticated."

---

## Step 4: Set GitHub Secrets

Go to your GitHub repo > Settings > Secrets and variables > Actions > New repository secret.

Add these three secrets:

**Secret 1: VPS_HOST**
- Name: `VPS_HOST`
- Value: Your VPS static IP address (e.g., `18.194.42.137`)

**Secret 2: VPS_USER**
- Name: `VPS_USER`
- Value: `deploy`

**Secret 3: VPS_SSH_KEY**
- Name: `VPS_SSH_KEY`
- Value: The contents of your **local** private key file

On your local machine, copy the key contents:

```bash
cat ~/.ssh/openclaw
```

Copy the ENTIRE output, including the `-----BEGIN OPENSSH PRIVATE KEY-----` and `-----END OPENSSH PRIVATE KEY-----` lines. Paste it as the secret value.

---

## Step 5: Prepare the VPS Directories

Before the first deploy, make sure the directories exist on your VPS:

```bash
ssh openclaw
mkdir -p ~/.openclaw/workspace
```

This is a one-time setup. After the first deploy, the workflow handles everything.

---

## Step 6: Push and Watch

Back on your **local machine**, commit and push:

```bash
cd ~/openclaw-deploy
git add .
git status
```

**CRITICAL:** Verify that `git status` does NOT show any secret files. You should see:
- `config/openclaw.json`
- `workspace/SOUL.md`
- `workspace/IDENTITY.md`
- `workspace/skills/` (if you have any)
- `docker-compose.yml`
- `.github/workflows/deploy.yml`
- `.gitignore`

You should NOT see:
- `.env`
- `secrets/` or anything inside it
- Any `.key` or `.pem` files

If that looks right:

```bash
git commit -m "Add GitHub Actions deploy workflow"
git push
```

---

## Step 7: Watch the Action Run

1. Go to your GitHub repo in the browser
2. Click the **Actions** tab
3. You should see a workflow run in progress (or just completed)
4. Click on it to see the details
5. Click on the "Deploy to VPS via SSH" step to see the output

You should see the SSH connection happening, the git clone (first time), the config copies, and the docker compose output.

If you see green checkmarks -- it worked!

If you see red X marks -- click on the failed step to see the error message. Common issues:
- **Permission denied** -- check that `VPS_SSH_KEY` contains your full private key
- **Host key verification failed** -- SSH into your VPS manually first to accept the host key
- **Repository not found** -- check that the deploy key is added to the repo
- **openclaw: command not found** -- make sure OpenClaw is installed globally on the VPS

---

## Step 8: Verify Files Landed on the VPS

SSH into your VPS:

```bash
ssh openclaw
```

Check that the repo was cloned:

```bash
ls -la ~/openclaw/
```

You should see your repo files: `config/`, `workspace/`, `docker-compose.yml`, `.github/`.

Check that configs were copied to the right places:

```bash
# OpenClaw config
cat ~/.openclaw/openclaw.json

# Workspace files
ls -la ~/.openclaw/workspace/
cat ~/.openclaw/workspace/SOUL.md
```

You should see your config and personality files in the OpenClaw config directory.

---

## Step 9: Test the Full Cycle -- The Magic Moment

Make a small change locally to prove the pipeline works end-to-end:

```bash
cd ~/openclaw-deploy
```

Edit `workspace/SOUL.md`. Add a line at the end:

```markdown
When someone says "deploy test", respond with "Pipeline working! 🚀"
```

Push the change:

```bash
git add workspace/SOUL.md
git commit -m "Add deploy test response to SOUL.md"
git push
```

Watch the Actions tab. When it completes, SSH in and verify:

```bash
ssh openclaw
cat ~/.openclaw/workspace/SOUL.md
```

You should see your new line. The change went from your editor to your server automatically.

That's it. That's the magic. You edited a personality file on your laptop, pushed to git, and your agent's brain updated on a server in a data center. No SSH, no manual copying, no restarts by hand.

---

## What Just Happened?

1. **Your Module 3 repo is now on GitHub** -- your configuration is version-controlled and recoverable
2. **You created a GitHub Actions workflow** -- deployment is automated
3. **You set up a deploy key** -- your VPS can pull from the private repo with read-only access
4. **You configured GitHub Secrets** -- SSH credentials are encrypted and only available to workflows
5. **The workflow copies configs to the right places** -- `config/` to `~/.openclaw/`, `workspace/` to `~/.openclaw/workspace/`
6. **You pushed and it deployed** -- from your editor to your server in under a minute

Your agent's configuration now lives in git. If your VPS dies, you spin up a new one, install Node.js and OpenClaw (Module 4), set the GitHub Secrets, push, and you're back in business.

---

## Try This (Optional)

1. **Break something on purpose.** Push a SOUL.md with a typo. Watch the deploy succeed (it's just a text file -- there's nothing to "break"). Then fix it and push again. Get comfortable with the cycle.

2. **Check the deploy time.** How many seconds from push to "files on server"? Look at the workflow duration in the Actions tab.

3. **Edit openclaw.json.** Change a configuration value in `config/openclaw.json`, push, and verify it landed at `~/.openclaw/openclaw.json` on the server.

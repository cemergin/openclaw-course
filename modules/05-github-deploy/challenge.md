# Challenge: Level Up Your Deploy Pipeline

## The Scenario

Your deploy pipeline works -- push to GitHub, configs land on your server, OpenClaw restarts. But right now it's bare-bones. Real CI/CD pipelines have notifications (so you know when a deploy succeeds or fails) and health checks (so you know the app is actually working after deployment). Let's add both.

---

## Task 1: Add a Deploy Notification via Telegram

When a deploy succeeds, wouldn't it be nice to get a message on your phone? Telegram has a dead-simple bot API that's perfect for this.

**What to do:**

1. Create a Telegram bot (if you haven't already from an earlier module):
   - Message [@BotFather](https://t.me/BotFather) on Telegram
   - Send `/newbot` and follow the prompts
   - Save the bot token it gives you

2. Get your chat ID:
   - Message your new bot (send it anything)
   - Visit `https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates` in your browser
   - Find your `chat.id` in the JSON response

3. Add two new GitHub Secrets:
   - `TELEGRAM_BOT_TOKEN` -- the bot token from BotFather
   - `TELEGRAM_CHAT_ID` -- your chat ID

4. Add a notification step to your workflow (after the deploy step):

   ```yaml
   - name: Notify on Telegram
     if: success()
     run: |
       curl -s -X POST \
         "https://api.telegram.org/bot${{ secrets.TELEGRAM_BOT_TOKEN }}/sendMessage" \
         -d chat_id=${{ secrets.TELEGRAM_CHAT_ID }} \
         -d text="Deploy successful! Commit: ${{ github.sha }}" \
         -d parse_mode=Markdown
   ```

5. Push a change and check your Telegram for the notification

**Bonus:** Add a failure notification too:

```yaml
- name: Notify on failure
  if: failure()
  run: |
    curl -s -X POST \
      "https://api.telegram.org/bot${{ secrets.TELEGRAM_BOT_TOKEN }}/sendMessage" \
      -d chat_id=${{ secrets.TELEGRAM_CHAT_ID }} \
      -d text="DEPLOY FAILED! Check: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}"
```

**Success criteria:**
- You receive a Telegram message when a deploy succeeds
- Bonus: You receive a different message when a deploy fails

---

## Task 2: Add a Health Check Step

After deploying, the workflow should verify that OpenClaw's gateway is actually running -- not just that the files were copied.

**What to do:**

1. Add a health check step after the deploy step in your workflow:

   ```yaml
   - name: Health check
     uses: appleboy/ssh-action@v1
     with:
       host: ${{ secrets.VPS_HOST }}
       username: ${{ secrets.VPS_USER }}
       key: ${{ secrets.VPS_SSH_KEY }}
       script: |
         # Wait for gateway to start
         sleep 5

         # Check OpenClaw gateway status
         openclaw gateway status

         # Check support services
         cd ~/openclaw
         docker compose ps

         # Verify gateway is listening on port 18789
         curl -sf http://127.0.0.1:18789/ > /dev/null && echo "Gateway is responding!" || (echo "Gateway is NOT responding!" && exit 1)
   ```

2. Push and verify the health check passes

**Success criteria:**
- The workflow includes a health check step that verifies the gateway is running
- If the gateway fails to start, the workflow fails (and you get notified via Telegram if you did Task 1)

---

## Task 3: Add a Manual Deploy Trigger

Sometimes you want to deploy without pushing a code change -- maybe you just want to restart the gateway or update OpenClaw. Add a manual trigger to your workflow.

**What to do:**

1. Update the `on:` section of your workflow:

   ```yaml
   on:
     push:
       branches: [main]
     workflow_dispatch:
   ```

2. Push this change

3. Go to the Actions tab in your repo. You should now see a "Run workflow" button that lets you trigger a deploy manually.

**Success criteria:**
- You can trigger a deploy from the GitHub Actions tab without pushing code
- The manual trigger runs the exact same deploy steps

---

## Hints

<details>
<summary>Hint 1: Complete workflow with all additions</summary>

```yaml
name: Deploy to VPS

on:
  push:
    branches: [main]
  workflow_dispatch:

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
            if [ ! -d ~/openclaw/.git ]; then
              cd ~ && rm -rf openclaw
              git clone ${{ github.event.repository.ssh_url }} openclaw
            else
              cd ~/openclaw && git pull origin main
            fi
            cp ~/openclaw/config/openclaw.json ~/.openclaw/openclaw.json
            mkdir -p ~/.openclaw/workspace
            cp -r ~/openclaw/workspace/* ~/.openclaw/workspace/
            sudo npm update -g openclaw
            openclaw gateway restart || openclaw gateway start
            cd ~/openclaw && docker compose up -d
            echo "Deploy complete!"

      - name: Health check
        uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.VPS_HOST }}
          username: ${{ secrets.VPS_USER }}
          key: ${{ secrets.VPS_SSH_KEY }}
          script: |
            sleep 5
            openclaw gateway status
            cd ~/openclaw && docker compose ps
            curl -sf http://127.0.0.1:18789/ > /dev/null && echo "Gateway responding!" || (echo "Gateway NOT responding!" && exit 1)

      - name: Notify success
        if: success()
        run: |
          curl -s -X POST \
            "https://api.telegram.org/bot${{ secrets.TELEGRAM_BOT_TOKEN }}/sendMessage" \
            -d chat_id=${{ secrets.TELEGRAM_CHAT_ID }} \
            -d text="Deploy successful! Commit: ${{ github.event.head_commit.message }}"

      - name: Notify failure
        if: failure()
        run: |
          curl -s -X POST \
            "https://api.telegram.org/bot${{ secrets.TELEGRAM_BOT_TOKEN }}/sendMessage" \
            -d chat_id=${{ secrets.TELEGRAM_CHAT_ID }} \
            -d text="Deploy FAILED! Check: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}"
```

</details>

<details>
<summary>Hint 2: Telegram bot setup</summary>

The BotFather flow:
1. Open Telegram and search for `@BotFather`
2. Send `/newbot`
3. Pick a name (e.g., "My Deploy Bot")
4. Pick a username (must end in `bot`, e.g., `openclaw_deploy_bot`)
5. BotFather gives you a token like `123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11`

For the chat ID: after messaging your bot, the getUpdates URL will return JSON. Look for `"chat":{"id":123456789}` -- that number is your chat ID.

</details>

---

## Solution

<details>
<summary>Click to reveal the full solution</summary>

### Task 1: Telegram Notification

1. Create bot with @BotFather, save the token
2. Get chat ID from the getUpdates endpoint
3. Add secrets `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` to GitHub
4. Add success/failure notification steps to the workflow (see Hint 1 for the complete file)

### Task 2: Health Check

Add the health check step after the deploy step. It:
- Waits 5 seconds for the gateway to initialize
- Runs `openclaw gateway status` to check the gateway
- Runs `docker compose ps` to check support services
- Curls the gateway endpoint to verify it's actually responding

### Task 3: Manual Deploy Trigger

Add `workflow_dispatch:` to the `on:` section. That's it -- one line. GitHub Actions automatically adds the "Run workflow" button to the Actions tab.

### Why This All Matters

- **Notifications** mean you don't have to stare at the Actions tab. Push and go on with your life -- your phone will tell you when it's done (or if it broke).
- **Health checks** catch the case where the deploy "succeeded" (files copied) but the gateway didn't actually start (bad config, missing secrets, etc.).
- **Manual triggers** let you redeploy or restart without pushing a fake commit.
- Together, they turn a basic deploy pipeline into something you can trust.

</details>

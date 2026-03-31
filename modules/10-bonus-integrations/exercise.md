# Exercise 10: Setting Up Your Integrations

## What We're Doing

Each section below is a self-contained mini-guide for one integration. Do any or all of them, in any order. Each ends with a test to verify it works.

Since OpenClaw runs natively, adding integrations follows the same pattern every time:
1. Create the secret file in `~/openclaw-deploy/secrets/`
2. Update `openclaw.json` with the integration config and SecretRef
3. Run `openclaw channels add` to register the channel (if needed)
4. Run `openclaw gateway restart` to pick up the changes

No `docker exec`. No container rebuilds. Just files and the native CLI.

## Prerequisites

- Native OpenClaw running on your VPS with SecretRef-based secrets
- SSH access to your VPS
- Your `starter/integration-checklist.md` open alongside this -- check things off as you go

---

## 1. GitHub -- Fine-Grained Tokens

**Time: ~15 minutes**

### Create a Read-Only Token

**1.** Go to [github.com/settings/personal-access-tokens/new](https://github.com/settings/personal-access-tokens/new)

Make sure you're on the **fine-grained** token page, not the classic tokens page. The URL should contain `personal-access-tokens`, not `tokens`.

**2.** Fill in the token details:

- **Token name:** `openclaw-readonly`
- **Expiration:** 90 days
- **Description:** `Read-only access for OpenClaw AI agent`
- **Resource owner:** Your personal account
- **Repository access:** Select "Only select repositories" and pick the repos you want your agent to see

**3.** Under **Permissions**, set:

- Contents: **Read-only**
- Metadata: **Read-only**
- Leave everything else at "No access"

**4.** Click "Generate token" and copy it immediately. You won't see it again.

### Create a Read-Write Token (Optional)

If you want your agent to create pull requests or push code:

**5.** Create another token at the same URL:

- **Token name:** `openclaw-readwrite`
- **Expiration:** 90 days
- **Repository access:** Only select repositories (be selective)
- **Permissions:**
  - Contents: **Read and Write**
  - Pull requests: **Read and Write**
  - Metadata: **Read-only**
  - Everything else: **No access**

### Store the Token and Update Config

**6.** SSH into your VPS and create the secret file:

```bash
ssh openclaw@<your-server-ip>
echo -n "github_pat_your_token_here" > ~/openclaw-deploy/secrets/github_token
chmod 600 ~/openclaw-deploy/secrets/github_token
```

**7.** Update your `openclaw.json` to add the GitHub integration with SecretRef:

```bash
nano ~/openclaw-deploy/openclaw.json
```

Add the GitHub section:

```json
{
  "github": {
    "token": {
      "source": "file",
      "id": "/home/openclaw/openclaw-deploy/secrets/github_token"
    }
  }
}
```

**8.** Register the GitHub channel and restart:

```bash
openclaw channels add github
openclaw gateway restart
```

### Test It

**9.** Send this message to your bot via Telegram:

> "What are the most recent commits in my [repo-name] repository?"

If the agent can list commits, your GitHub integration is working.

**10.** Set a calendar reminder for 90 days from now: "Rotate OpenClaw GitHub tokens."

> **Pro tip:** When you rotate, create the new token *before* deleting the old one. Update the secret file, restart the gateway, verify it works, then revoke the old token. Zero downtime.

---

## 2. Gmail -- OAuth2 Setup

**Time: ~30 minutes**

This one has more steps because OAuth2 requires a Google Cloud project. Take it slow.

### Create a Dedicated Gmail Account

**1.** Create a new Gmail account specifically for your agent. Something like `yourname.openclaw@gmail.com`.

Do NOT use your personal Gmail. Re-read the prompt injection section in the lesson if you need a reminder why.

**2.** Log into the new account in a browser. You'll use this session for the next steps.

### Set Up Google Cloud

**3.** Go to [console.cloud.google.com](https://console.cloud.google.com) (logged in as your new Gmail account).

**4.** Create a new project:

- Click the project dropdown at the top
- Click "New Project"
- Name: `openclaw-integrations`
- Click "Create"

**5.** Enable the Gmail API:

- Go to "APIs & Services" > "Library"
- Search for "Gmail API"
- Click it, then click "Enable"

### Configure OAuth

**6.** Go to "APIs & Services" > "OAuth consent screen":

- Choose "External" (unless you have a Google Workspace account)
- App name: `OpenClaw`
- User support email: your new Gmail address
- Developer contact: your new Gmail address
- Click "Save and Continue"

**7.** Add scopes:

- Click "Add or Remove Scopes"
- Find and select `https://www.googleapis.com/auth/gmail.readonly`
- This is the ONLY scope you need. Do not add send, modify, or full access.
- Click "Update," then "Save and Continue"

**8.** Add test users:

- Add your new Gmail address as a test user
- Click "Save and Continue"

**9.** Create credentials:

- Go to "APIs & Services" > "Credentials"
- Click "Create Credentials" > "OAuth client ID"
- Application type: **Desktop app**
- Name: `OpenClaw`
- Click "Create"

**10.** Download the credentials file:

- Click the download icon next to your new credential
- Save the file as `credentials.json`

### Upload to Your VPS

**11.** Upload the credentials file:

```bash
scp credentials.json openclaw@<your-server-ip>:~/openclaw-deploy/secrets/gmail_credentials.json
```

**12.** Set permissions:

```bash
ssh openclaw@<your-server-ip>
chmod 600 ~/openclaw-deploy/secrets/gmail_credentials.json
```

**13.** Follow OpenClaw's Gmail setup instructions to complete the OAuth authorization flow. This will generate a token file. Store that token as a secret file too:

```bash
chmod 600 ~/openclaw-deploy/secrets/gmail_token.json
```

**14.** Update `openclaw.json` with SecretRef entries for Gmail credentials:

```json
{
  "gmail": {
    "credentials": {
      "source": "file",
      "id": "/home/openclaw/openclaw-deploy/secrets/gmail_credentials.json"
    },
    "token": {
      "source": "file",
      "id": "/home/openclaw/openclaw-deploy/secrets/gmail_token.json"
    }
  }
}
```

**15.** Register the channel and restart:

```bash
openclaw channels add gmail
openclaw gateway restart
```

### Set Up Gmail Filters

**16.** In your new Gmail account, go to Settings > Filters and Blocked Addresses. Create a filter:

- Matches: `from:(-newsletter1@example.com -newsletter2@example.com)` (replace with your actual subscriptions)
- Action: Delete it

This ensures only emails from sources you've explicitly allowed reach the inbox. Everything else gets auto-deleted.

### Test It

**17.** Subscribe to a newsletter you want to receive (using the new Gmail address).

**18.** Once an email arrives, message your bot:

> "Check my email and summarize any new messages"

If the agent can read and summarize the email, Gmail is working.

---

## 3. Notion -- Tasks and Notes

**Time: ~20 minutes**

### Create the Integration

**1.** Go to [notion.so/my-integrations](https://www.notion.so/my-integrations) and click "New integration."

**2.** Configure it:

- **Name:** OpenClaw
- **Associated workspace:** Your workspace
- **Capabilities:** Check "Read content," "Update content," and "Insert content"
- Do NOT check "Read user information"

**3.** Click "Submit" and copy the integration token (it starts with `ntn_...`).

### Set Up Your Databases

**4.** In Notion, create a database called **Tasks** with these properties:

| Property | Type |
|---|---|
| Name | Title (default) |
| Status | Status (Not started / In progress / Done) |
| Priority | Select (High / Medium / Low) |
| Due Date | Date |
| Tags | Multi-select |
| Source | Select (Telegram / Manual / Other) |

**5.** Share the database with your integration: click the "..." menu on the database page, then "Connections," then find and add "OpenClaw."

**6.** (Optional) Create a **Notes** database and a **Reading List** database. Share each with the integration.

### Store the Token and Update Config

**7.** SSH into your VPS:

```bash
echo -n "ntn_your_token_here" > ~/openclaw-deploy/secrets/notion_token
chmod 600 ~/openclaw-deploy/secrets/notion_token
```

**8.** Update `openclaw.json`:

```json
{
  "notion": {
    "token": {
      "source": "file",
      "id": "/home/openclaw/openclaw-deploy/secrets/notion_token"
    }
  }
}
```

**9.** Register and restart:

```bash
openclaw channels add notion
openclaw gateway restart
```

### Test It

**10.** Send your bot a Telegram message:

> "Add a task to Notion: Review the quarterly metrics deck, high priority, due Friday"

Check your Notion Tasks database. If a new entry appeared with the right properties, you're golden.

**11.** Try a note:

> "Save a note to Notion: The dedicated account pattern means creating separate accounts for AI agents to limit blast radius"

---

## 4. Google Drive -- File Storage

**Time: ~20 minutes (less if you already did Gmail)**

### Enable the API

**1.** Go to the same Google Cloud project you used for Gmail (or create one if you skipped Gmail -- follow steps 3-4 from the Gmail section).

**2.** Go to "APIs & Services" > "Library" and enable the **Google Drive API**.

### Add the Drive Scope

**3.** Go to "APIs & Services" > "OAuth consent screen" > "Edit App":

- Under Scopes, add `https://www.googleapis.com/auth/drive.file`
- This is the `drive.file` scope -- only files the app creates or you share. NOT full Drive access.
- Save the changes.

**4.** Re-authorize: because you added a new scope, you'll need to go through the OAuth flow again. OpenClaw will prompt you when it tries to use Drive.

**5.** Store any new token files as secret files with `chmod 600` and add SecretRef entries to `openclaw.json`.

**6.** Register and restart:

```bash
openclaw channels add drive
openclaw gateway restart
```

### Test It

**7.** Send your bot a Telegram message:

> "Create a text file in Google Drive called 'test.txt' with the content 'Hello from OpenClaw'"

Check your dedicated Google Drive account. If `test.txt` appeared, Drive is working.

---

## What Just Happened?

Look at what you've done. Your AI agent can now:

- Read your code on GitHub (and optionally push changes)
- Read your newsletters without you opening Gmail
- Capture tasks and notes in Notion
- Store files in Google Drive

And every single integration follows the same security pattern:

- Scoped, least-privilege access
- Credentials stored as files with `chmod 600`, referenced via SecretRef in `openclaw.json`
- Dedicated accounts where applicable
- Registered via `openclaw channels add` and activated with `openclaw gateway restart`
- Expiration and rotation built into the plan

You didn't just connect some APIs. You connected them *correctly* -- in a way that you can explain, defend, and maintain.

## Try This (Optional Experiments)

- **Chain integrations:** Send a message like "Search the web for the top 3 Terraform best practices and save them as a note in Notion." See if your agent can combine search and Notion in one go.
- **Test your blast radius:** For each integration, ask yourself: "If this token leaked right now, what's the worst someone could do?" If the answer is too scary, tighten the scopes.
- **Add another GitHub repo:** Create a new fine-grained token scoped to different repos. Observe how easy rotation becomes when each token is narrowly scoped.

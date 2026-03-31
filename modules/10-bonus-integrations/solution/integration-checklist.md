# Integration Security Checklist -- COMPLETED EXAMPLE (Hybrid Stack)

This is what a completed checklist looks like after setting up all integrations
and running the security audit. Your specific dates and account names will differ.

---

## GitHub

- [x] Created fine-grained token (NOT classic token)
- [x] Token scoped to specific repositories only
- [x] Read-only token: Contents Read-only + Metadata Read-only
- [x] Read-write token (if created): Contents R+W, Pull Requests R+W, Metadata Read-only
- [x] NO access granted to: Administration, Actions, Workflows, Environments, Secrets, Pages
- [x] Token stored in `~/openclaw-deploy/secrets/github_token` (not .env)
- [x] File permissions: `chmod 600`
- [x] `openclaw.json` updated with SecretRef for GitHub token
- [x] Token expiration set to 90 days
- [x] Calendar reminder set for rotation date: June 28, 2026
- [x] Ran `openclaw channels add github` and `openclaw gateway restart`
- [x] Tested: agent can read repo contents via Telegram

**Blast radius if leaked:** Attacker could read code in 3 specific repos (read-only token) or push code/create PRs in 2 repos (read-write token). Cannot access account settings, actions, secrets, or other repos.

---

## Gmail

- [x] Created DEDICATED Gmail account (not personal): cem.openclaw@gmail.com
- [x] Google Cloud project created
- [x] Gmail API enabled
- [x] OAuth consent screen configured
- [x] Scope set to `gmail.readonly` ONLY (no send, no modify, no full access)
- [x] OAuth credentials created (Desktop app type)
- [x] credentials.json uploaded to VPS with `chmod 600`
- [x] OAuth token stored as secret file with `chmod 600`
- [x] `openclaw.json` updated with SecretRef for Gmail credentials and token
- [x] Gmail filters configured to auto-delete from unknown senders
- [x] Agent email address NOT posted publicly anywhere
- [x] Ran `openclaw channels add gmail` and `openclaw gateway restart`
- [x] Tested: agent can read and summarize an email

**Blast radius if leaked:** Attacker could read emails in the dedicated agent inbox (newsletters and subscriptions only -- not personal email). Cannot send emails, modify, or delete. Exposure limited to whatever newsletters I've subscribed to with this address.

---

## Notion

- [x] Integration created at notion.so/my-integrations
- [x] Capabilities: Read + Update + Insert content only
- [x] "Read user information" NOT checked
- [x] Token (ntn_...) stored in `~/openclaw-deploy/secrets/notion_token`
- [x] File permissions: `chmod 600`
- [x] `openclaw.json` updated with SecretRef for Notion token
- [x] Shared ONLY specific databases with the integration (not entire workspace)
- [x] Databases shared:
  - [x] Tasks
  - [x] Notes (optional)
  - [x] Reading List (optional)
- [x] Ran `openclaw channels add notion` and `openclaw gateway restart`
- [x] Tested: agent can create a task in Notion via Telegram

**Blast radius if leaked:** Attacker could read, modify, or add entries to my Tasks, Notes, and Reading List databases. Cannot see any other pages in my workspace. Could inject misleading tasks/notes, but cannot access anything sensitive.

---

## Google Drive

- [x] Google Drive API enabled (same Google Cloud project as Gmail)
- [x] Scope set to `drive.file` ONLY (not full Drive access)
- [x] Re-authorized after adding Drive scope
- [x] Token stored as secret file with `chmod 600`
- [x] `openclaw.json` updated with SecretRef for Drive token
- [x] Ran `openclaw channels add drive` and `openclaw gateway restart`
- [x] Tested: agent can create a file in Drive

**Blast radius if leaked:** Attacker could read/modify files the agent created and files I explicitly shared with the app. Cannot browse or access any other files in Drive. Limited to the dedicated Google account's Drive, not my personal Drive.

---

## Global Security Checks

- [x] All secret files have `600` permissions: `ls -la ~/openclaw-deploy/secrets/`
  ```
  -rw-------  1 openclaw openclaw   56 Mar 30 10:00 anthropic_api_key
  -rw-------  1 openclaw openclaw   93 Mar 30 10:00 github_token
  -rw-------  1 openclaw openclaw  1204 Mar 30 10:30 gmail_credentials.json
  -rw-------  1 openclaw openclaw   892 Mar 30 10:35 gmail_token.json
  -rw-------  1 openclaw openclaw   50 Mar 30 10:20 notion_token
  -rw-------  1 openclaw openclaw  168 Mar 30 09:00 cloudflare_tunnel_token
  ```
- [x] Secrets directory has `700` permissions: `ls -la ~/openclaw-deploy/ | grep secrets`
  ```
  drwx------  2 openclaw openclaw 4096 Mar 30 10:35 secrets
  ```
- [x] `openclaw.json` uses SecretRef for all credentials (no inline keys)
  ```json
  {
    "anthropic": {
      "api_key": { "source": "file", "id": "/home/openclaw/openclaw-deploy/secrets/anthropic_api_key" }
    },
    "github": {
      "token": { "source": "file", "id": "/home/openclaw/openclaw-deploy/secrets/github_token" }
    }
  }
  ```
- [x] No secrets in `.env` file (only non-secret config)
- [x] No secrets visible in `docker inspect` output for any support container

---

## Rotation Calendar

| Token | Created | Expires | Reminder Date |
|---|---|---|---|
| GitHub read-only | Mar 30, 2026 | Jun 28, 2026 | Jun 21, 2026 |
| GitHub read-write | Mar 30, 2026 | Jun 28, 2026 | Jun 21, 2026 |
| Notion | Mar 30, 2026 | Check quarterly | Jun 30, 2026 |
| Gmail OAuth | Mar 30, 2026 | Check quarterly | Jun 30, 2026 |

---

**Last audited:** March 30, 2026
**Next audit due:** June 30, 2026

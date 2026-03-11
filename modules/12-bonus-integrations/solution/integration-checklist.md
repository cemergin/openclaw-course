# Integration Security Checklist -- COMPLETED EXAMPLE

This is what a completed checklist looks like after setting up all integrations
and running the security audit. Your specific dates and account names will differ.

---

## GitHub

- [x] Created fine-grained token (NOT classic token)
- [x] Token scoped to specific repositories only
- [x] Read-only token: Contents Read-only + Metadata Read-only
- [x] Read-write token (if created): Contents R+W, Pull Requests R+W, Metadata Read-only
- [x] NO access granted to: Administration, Actions, Workflows, Environments, Secrets, Pages
- [x] Token stored in `~/openclaw/secrets/github_token` (not .env)
- [x] File permissions: `chmod 600 ~/openclaw/secrets/github_token`
- [x] Token expiration set to 90 days
- [x] Calendar reminder set for rotation date: June 9, 2026
- [x] Tested: agent can read repo contents via WhatsApp

**Blast radius if leaked:** Attacker could read code in 3 specific repos (read-only token) or push code/create PRs in 2 repos (read-write token). Cannot access account settings, actions, secrets, or other repos.

---

## Web Search (SearXNG)

- [x] SearXNG container running (`docker compose ps`)
- [x] Accessible at `127.0.0.1:8080` (localhost only, NOT public)
- [x] Tested: agent returns current web information

## Web Search (Tavily -- Optional)

- [x] API key stored in `~/openclaw/secrets/tavily_api_key`
- [x] File permissions: `chmod 600`
- [x] Tested: agent uses Tavily for search queries

**Blast radius if leaked:** Attacker could use my Tavily free-tier quota (1,000 searches/month). No access to personal data. Annoying, not dangerous.

---

## Notion

- [x] Integration created at notion.so/my-integrations
- [x] Capabilities: Read + Update + Insert content only
- [x] "Read user information" NOT checked
- [x] Token (ntn_...) stored in `~/openclaw/secrets/notion_token`
- [x] File permissions: `chmod 600`
- [x] Shared ONLY specific databases with the integration (not entire workspace)
- [x] Databases shared:
  - [x] Tasks
  - [x] Notes (optional)
  - [x] Reading List (optional)
- [x] Tested: agent can create a task in Notion via WhatsApp

**Blast radius if leaked:** Attacker could read, modify, or add entries to my Tasks, Notes, and Reading List databases. Cannot see any other pages in my workspace. Could be used to inject misleading tasks/notes, but cannot access anything sensitive.

---

## Gmail

- [x] Created DEDICATED Gmail account (not personal): cem.openclaw@gmail.com
- [x] Google Cloud project created
- [x] Gmail API enabled
- [x] OAuth consent screen configured
- [x] Scope set to `gmail.readonly` ONLY (no send, no modify, no full access)
- [x] OAuth credentials created (Desktop app type)
- [x] credentials.json uploaded to VPS with `chmod 600`
- [x] OAuth token stored as Docker secret with `chmod 600`
- [x] Gmail filters configured to auto-delete from unknown senders
- [x] Agent email address NOT posted publicly anywhere
- [x] Tested: agent can read and summarize an email

**Blast radius if leaked:** Attacker could read emails in the dedicated agent inbox (newsletters and subscriptions only -- not personal email). Cannot send emails, modify, or delete. Exposure limited to whatever newsletters I've subscribed to with this address.

---

## Google Drive

- [x] Google Drive API enabled (same Google Cloud project as Gmail)
- [x] Scope set to `drive.file` ONLY (not full Drive access)
- [x] Re-authorized after adding Drive scope
- [x] Token stored as Docker secret with `chmod 600`
- [x] Tested: agent can create a file in Drive

**Blast radius if leaked:** Attacker could read/modify files the agent created and files I explicitly shared with the app. Cannot browse or access any other files in Drive. Limited to the dedicated Google account's Drive, not my personal Drive.

---

## Global Security Checks

- [x] All secret files have `600` permissions: `ls -la ~/openclaw/secrets/`
  ```
  -rw-------  1 openclaw openclaw   56 Mar 11 10:00 anthropic_api_key
  -rw-------  1 openclaw openclaw   93 Mar 11 10:00 github_token
  -rw-------  1 openclaw openclaw  1204 Mar 11 10:30 gmail_credentials.json
  -rw-------  1 openclaw openclaw   892 Mar 11 10:35 gmail_token.json
  -rw-------  1 openclaw openclaw   50 Mar 11 10:20 notion_token
  -rw-------  1 openclaw openclaw   35 Mar 11 10:15 tavily_api_key
  -rw-------  1 openclaw openclaw  156 Mar 11 09:00 whatsapp_access_token
  -rw-------  1 openclaw openclaw   32 Mar 11 09:00 whatsapp_app_secret
  -rw-------  1 openclaw openclaw   24 Mar 11 09:00 whatsapp_verify_token
  ```
- [x] Secrets directory has `700` permissions: `ls -la ~/openclaw/ | grep secrets`
  ```
  drwx------  2 openclaw openclaw 4096 Mar 11 10:35 secrets
  ```
- [x] No secrets visible in `docker inspect openclaw` output
  ```
  $ docker inspect openclaw --format '{{json .Config.Env}}' | python3 -m json.tool
  [
      "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
      "ALLOWED_NUMBERS=+905551234567",
      "SEARXNG_BASE_URL=http://searxng:8080",
      "LOG_LEVEL=info"
  ]
  # No API keys or tokens visible -- only non-secret config.
  ```
- [x] No secrets in `.env` file (only non-secret config)
- [x] Entrypoint wrapper converts secrets to env vars at runtime

---

## Rotation Calendar

| Token | Created | Expires | Reminder Date |
|---|---|---|---|
| GitHub read-only | Mar 11, 2026 | Jun 9, 2026 | Jun 2, 2026 |
| GitHub read-write | Mar 11, 2026 | Jun 9, 2026 | Jun 2, 2026 |
| Notion | Mar 11, 2026 | Check quarterly | Jun 11, 2026 |
| Gmail OAuth | Mar 11, 2026 | Check quarterly | Jun 11, 2026 |
| Tavily | Mar 11, 2026 | Check quarterly | Jun 11, 2026 |

---

**Last audited:** March 11, 2026
**Next audit due:** June 11, 2026

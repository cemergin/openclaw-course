# Integration Security Checklist

Use this checklist as you set up each integration. Check items off as you complete them.
After setup, use it again for the security audit challenge.

---

## GitHub

- [ ] Created fine-grained token (NOT classic token)
- [ ] Token scoped to specific repositories only
- [ ] Read-only token: Contents Read-only + Metadata Read-only
- [ ] Read-write token (if created): Contents R+W, Pull Requests R+W, Metadata Read-only
- [ ] NO access granted to: Administration, Actions, Workflows, Environments, Secrets, Pages
- [ ] Token stored in `~/openclaw/secrets/github_token` (not .env)
- [ ] File permissions: `chmod 600 ~/openclaw/secrets/github_token`
- [ ] Token expiration set to 90 days
- [ ] Calendar reminder set for rotation date: ___________
- [ ] Tested: agent can read repo contents via WhatsApp

**Blast radius if leaked:** _________________________________________________

---

## Web Search (SearXNG)

- [ ] SearXNG container running (`docker compose ps`)
- [ ] Accessible at `127.0.0.1:8080` (localhost only, NOT public)
- [ ] Tested: agent returns current web information

## Web Search (Tavily -- Optional)

- [ ] API key stored in `~/openclaw/secrets/tavily_api_key`
- [ ] File permissions: `chmod 600`
- [ ] Tested: agent uses Tavily for search queries

**Blast radius if leaked:** _________________________________________________

---

## Notion

- [ ] Integration created at notion.so/my-integrations
- [ ] Capabilities: Read + Update + Insert content only
- [ ] "Read user information" NOT checked
- [ ] Token (ntn_...) stored in `~/openclaw/secrets/notion_token`
- [ ] File permissions: `chmod 600`
- [ ] Shared ONLY specific databases with the integration (not entire workspace)
- [ ] Databases shared:
  - [ ] Tasks
  - [ ] Notes (optional)
  - [ ] Reading List (optional)
- [ ] Tested: agent can create a task in Notion via WhatsApp

**Blast radius if leaked:** _________________________________________________

---

## Gmail

- [ ] Created DEDICATED Gmail account (not personal): ___________________@gmail.com
- [ ] Google Cloud project created
- [ ] Gmail API enabled
- [ ] OAuth consent screen configured
- [ ] Scope set to `gmail.readonly` ONLY (no send, no modify, no full access)
- [ ] OAuth credentials created (Desktop app type)
- [ ] credentials.json uploaded to VPS with `chmod 600`
- [ ] OAuth token stored as Docker secret with `chmod 600`
- [ ] Gmail filters configured to auto-delete from unknown senders
- [ ] Agent email address NOT posted publicly anywhere
- [ ] Tested: agent can read and summarize an email

**Blast radius if leaked:** _________________________________________________

---

## Google Drive

- [ ] Google Drive API enabled (same Google Cloud project as Gmail)
- [ ] Scope set to `drive.file` ONLY (not full Drive access)
- [ ] Re-authorized after adding Drive scope
- [ ] Token stored as Docker secret with `chmod 600`
- [ ] Tested: agent can create a file in Drive

**Blast radius if leaked:** _________________________________________________

---

## Global Security Checks

- [ ] All secret files have `600` permissions: `ls -la ~/openclaw/secrets/`
- [ ] Secrets directory has `700` permissions: `ls -la ~/openclaw/ | grep secrets`
- [ ] No secrets visible in `docker inspect openclaw` output
- [ ] No secrets in `.env` file (only non-secret config)
- [ ] Entrypoint wrapper converts secrets to env vars at runtime

---

## Rotation Calendar

| Token | Created | Expires | Reminder Date |
|---|---|---|---|
| GitHub read-only | | | |
| GitHub read-write | | | |
| Notion | | Check quarterly | |
| Gmail OAuth | | Check quarterly | |
| Tavily | | Check quarterly | |

---

**Last audited:** ___________
**Next audit due:** ___________

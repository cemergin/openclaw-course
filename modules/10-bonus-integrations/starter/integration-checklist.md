# Integration Security Checklist (Hybrid Stack)

Use this checklist as you set up each integration. Check items off as you complete them.
After setup, use it again for the security audit in the challenge.

---

## GitHub

- [ ] Created fine-grained token (NOT classic token)
- [ ] Token scoped to specific repositories only
- [ ] Read-only token: Contents Read-only + Metadata Read-only
- [ ] Read-write token (if created): Contents R+W, Pull Requests R+W, Metadata Read-only
- [ ] NO access granted to: Administration, Actions, Workflows, Environments, Secrets, Pages
- [ ] Token stored in `~/openclaw-deploy/secrets/github_token` (not .env)
- [ ] File permissions: `chmod 600`
- [ ] `openclaw.json` updated with SecretRef for GitHub token
- [ ] Token expiration set to 90 days
- [ ] Calendar reminder set for rotation date: ___________
- [ ] Ran `openclaw channels add github` and `openclaw gateway restart`
- [ ] Tested: agent can read repo contents via Telegram

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
- [ ] OAuth token stored as secret file with `chmod 600`
- [ ] `openclaw.json` updated with SecretRef for Gmail credentials and token
- [ ] Gmail filters configured to auto-delete from unknown senders
- [ ] Agent email address NOT posted publicly anywhere
- [ ] Ran `openclaw channels add gmail` and `openclaw gateway restart`
- [ ] Tested: agent can read and summarize an email

**Blast radius if leaked:** _________________________________________________

---

## Notion

- [ ] Integration created at notion.so/my-integrations
- [ ] Capabilities: Read + Update + Insert content only
- [ ] "Read user information" NOT checked
- [ ] Token (ntn_...) stored in `~/openclaw-deploy/secrets/notion_token`
- [ ] File permissions: `chmod 600`
- [ ] `openclaw.json` updated with SecretRef for Notion token
- [ ] Shared ONLY specific databases with the integration (not entire workspace)
- [ ] Databases shared:
  - [ ] Tasks
  - [ ] Notes (optional)
  - [ ] Reading List (optional)
- [ ] Ran `openclaw channels add notion` and `openclaw gateway restart`
- [ ] Tested: agent can create a task in Notion via Telegram

**Blast radius if leaked:** _________________________________________________

---

## Google Drive

- [ ] Google Drive API enabled (same Google Cloud project as Gmail)
- [ ] Scope set to `drive.file` ONLY (not full Drive access)
- [ ] Re-authorized after adding Drive scope
- [ ] Token stored as secret file with `chmod 600`
- [ ] `openclaw.json` updated with SecretRef for Drive token
- [ ] Ran `openclaw channels add drive` and `openclaw gateway restart`
- [ ] Tested: agent can create a file in Drive

**Blast radius if leaked:** _________________________________________________

---

## Global Security Checks

- [ ] All secret files have `600` permissions: `ls -la ~/openclaw-deploy/secrets/`
- [ ] Secrets directory has `700` permissions: `ls -la ~/openclaw-deploy/ | grep secrets`
- [ ] `openclaw.json` uses SecretRef for all credentials (no inline keys)
- [ ] No secrets in `.env` file (only non-secret config)
- [ ] No secrets visible in `docker inspect` output for any support container

---

## Rotation Calendar

| Token | Created | Expires | Reminder Date |
|---|---|---|---|
| GitHub read-only | | | |
| GitHub read-write | | | |
| Notion | | Check quarterly | |
| Gmail OAuth | | Check quarterly | |

---

**Last audited:** ___________
**Next audit due:** ___________

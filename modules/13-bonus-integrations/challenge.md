# Challenge 12: Integration Security Audit

## The Scenario

You're three months into running your OpenClaw setup. A security-minded friend asks: "How do you know your integrations are configured safely? When did you last rotate your tokens?" You want to have a good answer.

Your task: audit every integration you set up in this module against a security checklist, verify the technical details are correct, and create a personal rotation calendar so tokens don't silently expire and break your setup at 2am.

## Your Task

### Part 1: Security Audit

For each integration you configured, verify the following:

1. **Token scope** -- Is it least-privilege? Can you reduce the permissions further without breaking functionality?
2. **Storage** -- Is the token stored as a Docker secret (file in `~/openclaw/secrets/`)? Not in `.env`?
3. **File permissions** -- Does `ls -la ~/openclaw/secrets/` show `-rw-------` (600) for every secret file?
4. **Docker inspect** -- Run `docker inspect openclaw | grep -i "env"` -- do any secrets appear in the environment output?
5. **Blast radius** -- For each token, write one sentence: "If this leaked, an attacker could ___."

### Part 2: Gmail-Specific Audit (If You Set It Up)

6. **Scope check** -- Confirm the OAuth scope is `gmail.readonly` only (no send, no modify)
7. **Filters** -- Log into the dedicated Gmail account. Are filters configured to auto-delete from unknown senders?
8. **Account isolation** -- Is this a dedicated account, separate from your personal Gmail?
9. **Public exposure** -- Search for the agent's email address on the web. It should return zero results.

### Part 3: Rotation Calendar

10. **Create reminders** for every token that expires:

| Token | Created | Expires | Reminder Set? |
|---|---|---|---|
| GitHub read-only | [date] | [date + 90 days] | [ ] |
| GitHub read-write | [date] | [date + 90 days] | [ ] |
| Notion | [date] | No expiry (check quarterly) | [ ] |
| Gmail OAuth | [date] | Refresh auto, check quarterly | [ ] |
| Tavily | [date] | No expiry (check quarterly) | [ ] |

Set actual calendar reminders (Google Calendar, phone alarm, Notion recurring task -- whatever you'll actually see).

## Success Criteria

- Every secret file has `600` permissions
- No secrets appear in `docker inspect` output
- You can state the blast radius for each integration in one sentence
- Gmail filters are active (if applicable)
- You have calendar reminders set for token rotation
- Your completed `integration-checklist.md` has every applicable item checked

## Hints

<details>
<summary>Hint 1: Checking token scopes</summary>

For GitHub, go to github.com/settings/personal-access-tokens and click each token. The permissions are listed right there. For Google, go to myaccount.google.com/permissions and find "OpenClaw" -- it shows exactly what scopes you authorized.

</details>

<details>
<summary>Hint 2: The docker inspect check</summary>

The command you want is:

```bash
docker inspect openclaw --format '{{json .Config.Env}}' | python3 -m json.tool
```

This shows all environment variables in the container. Your API keys and tokens should NOT appear here. If they do, they're being passed as environment variables instead of file-based secrets. Go back to Module 6 and fix this.

</details>

## Solution

The completed checklist is in `solution/integration-checklist.md`. But the real value of this challenge is going through the audit yourself -- the solution is just a reference for what a completed audit looks like.

### The Meta-Lesson

Here's what this audit is really about: **security is maintenance, not installation.**

Setting up Docker secrets correctly on day one is great. But if you never check that permissions haven't changed, never rotate tokens, and never verify that new configurations didn't introduce a .env leak -- your security degrades over time.

The checklist you just filled out? Do it again in three months. And three months after that. It takes ten minutes and it's the difference between "I think my setup is secure" and "I verified it last Tuesday."

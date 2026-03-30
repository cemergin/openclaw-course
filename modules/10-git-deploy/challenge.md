# Challenge: Disaster Recovery Drill

## The Scenario

It's 2am. Your VPS provider emails you: "Due to a hardware failure, your instance has been terminated. Your data is unrecoverable." (This happens. Not often, but it happens.)

How fast can you get your bot back online?

## Your Task

Simulate a disaster recovery by rebuilding your OpenClaw setup on a fresh environment. You don't need to actually destroy your server — just prove you *could* rebuild it.

1. **Document the rebuild process** — Write a step-by-step runbook that goes from "new VPS" to "bot responding on WhatsApp." Include every command.

2. **Identify what's in git vs what's not** — List everything you'd need that ISN'T in your GitHub repo (secrets, DNS config, Cloudflare tunnel setup, Meta webhook URL).

3. **Time estimate** — Based on your runbook, estimate how long a rebuild would take. Be honest.

4. **Find the gaps** — What would you lose that can't be recovered? (Chat history? Custom configurations that aren't in git yet?)

## Success Criteria

- A written runbook that someone else could follow
- Clear separation of "from git" vs "manual steps"
- Honest assessment of recovery time
- At least one improvement identified (something you should add to git or document that you haven't yet)

## Hints

<details>
<summary>Hint 1: The rebuild order matters</summary>

You can't set up the tunnel before Docker is installed, and you can't configure webhooks before the tunnel is running. The order is roughly:

1. New VPS + SSH access
2. Create user, install Docker
3. Clone config repo
4. Recreate secrets from password manager
5. Start services
6. Verify tunnel reconnects (it should — same token, same tunnel ID)
7. Verify WhatsApp webhooks still work (same URL)

</details>

<details>
<summary>Hint 2: What you'd lose</summary>

Things NOT in your git repo that you'd need to recreate:
- Secret values (should be in your password manager)
- Cloudflare tunnel token (in your Cloudflare dashboard)
- UFW configuration (in your runbook)
- SSH keys (generate new ones, add to the new server)
- Any Docker volumes with persistent data

</details>

# Security Checklist -- OpenClaw on the Cloud (Hybrid Stack)

Print this out or keep it open in a tab. Every time you change your setup, come back here.

## Firewall and Network

- [ ] UFW enabled with default deny incoming
- [ ] SSH (port 22) allowed
- [ ] All Docker support container port bindings use `127.0.0.1:` prefix
- [ ] Native OpenClaw gateway port (18789) blocked from outside by UFW
- [ ] Cloudflare Tunnel running as Docker container
- [ ] No unnecessary ports open to the internet
- [ ] Port scan from outside shows only SSH (or nothing)

## Secrets -- OpenClaw (Native)

- [ ] Secrets directory created (`~/openclaw-deploy/secrets/`) with `chmod 700`
- [ ] Each secret in its own file with `chmod 600`
- [ ] `openclaw.json` uses SecretRef pattern: `{ "source": "file", "id": "/path/to/secret" }`
- [ ] No inline API keys or tokens in `openclaw.json`
- [ ] No secrets in environment variables
- [ ] No secrets committed to git (check with `git log --all -p | grep -i "api_key\|token\|secret"`)
- [ ] `.gitignore` includes `secrets/` directory

## Secrets -- Docker Support Services

- [ ] Cloudflare tunnel token stored as Docker Compose secret
- [ ] Support service secrets use Docker secrets or `.env.secrets` (gitignored)
- [ ] `docker inspect` does NOT show any API keys or tokens for any container
- [ ] `.env.secrets` is in `.gitignore`

## System Hardening

- [ ] Running as dedicated `openclaw` user, not root
- [ ] SSH key-only authentication (password login disabled)
- [ ] Automatic OS security updates enabled (unattended-upgrades)
- [ ] SSH directory permissions: `~/.ssh/` is `700`, `authorized_keys` is `600`

## Monitoring and Response

- [ ] Uptime Kuma monitoring configured
- [ ] Health check endpoint available
- [ ] Alert notifications set up (push/email)
- [ ] Kill switch URL bookmarked on phone
- [ ] Kill + revive cycle tested at least once

## Notes

Use this space to track what you've done and what's left:

| Date | Change Made | Checklist Items Verified |
|------|-------------|------------------------|
|      |             |                        |
|      |             |                        |
|      |             |                        |

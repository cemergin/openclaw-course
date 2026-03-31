# Security Checklist -- OpenClaw on the Cloud (COMPLETED after Module 7)

## Firewall and Network

- [x] UFW enabled with default deny incoming
- [x] SSH (port 22) allowed
- [x] All Docker support container port bindings use `127.0.0.1:` prefix
- [x] Native OpenClaw gateway port (18789) blocked from outside by UFW
- [ ] Cloudflare Tunnel running as Docker container -- *Module 8*
- [x] No unnecessary ports open to the internet
- [x] Port scan from outside shows only SSH (or nothing)

## Secrets -- OpenClaw (Native)

- [x] Secrets directory created (`~/openclaw-deploy/secrets/`) with `chmod 700`
- [x] Each secret in its own file with `chmod 600`
- [x] `openclaw.json` uses SecretRef pattern: `{ "source": "file", "id": "/path/to/secret" }`
- [x] No inline API keys or tokens in `openclaw.json`
- [x] No secrets in environment variables
- [x] No secrets committed to git
- [x] `.gitignore` includes `secrets/` directory

## Secrets -- Docker Support Services

- [x] Cloudflare tunnel token stored as Docker Compose secret (ready for Module 8)
- [x] Support service secrets use Docker secrets or `.env.secrets` (gitignored)
- [x] `docker inspect` does NOT show any API keys or tokens for any container
- [x] `.env.secrets` is in `.gitignore`

## System Hardening

- [x] Running as dedicated `openclaw` user, not root
- [x] SSH key-only authentication (password login disabled) -- *completed in challenge*
- [x] Automatic OS security updates enabled (unattended-upgrades)
- [x] SSH directory permissions: `~/.ssh/` is `700`, `authorized_keys` is `600`

## Monitoring and Response

- [ ] Uptime Kuma monitoring configured -- *Module 9*
- [ ] Health check endpoint available -- *Module 9*
- [ ] Alert notifications set up (push/email) -- *Module 9*
- [ ] Kill switch URL bookmarked on phone -- *Module 9*
- [ ] Kill + revive cycle tested at least once -- *Module 9*

## Notes

| Date | Change Made | Checklist Items Verified |
|------|-------------|------------------------|
| Today | UFW enabled, deny all incoming, allow SSH | Firewall section |
| Today | unattended-upgrades installed and enabled | System hardening |
| Today | Secrets directory created, files with chmod 600 | Secrets section |
| Today | openclaw.json updated with SecretRef pattern | Secrets -- OpenClaw |
| Today | Docker compose secrets configured for support services | Secrets -- Docker |
| Today | All Docker ports bound to 127.0.0.1 | Firewall section |
| Today | SSH password auth disabled (challenge) | System hardening |

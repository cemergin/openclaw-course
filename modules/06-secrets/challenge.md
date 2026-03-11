# Challenge: Prove .env Is Dangerous

## The Scenario

Your colleague just deployed a new service on the team's shared VPS. They used a `.env` file for configuration -- including the production API key for a paid service. "It works fine," they tell you. "Everyone does it this way."

Your job: demonstrate exactly how easy it is to extract secrets from a `.env`-based deployment, then show them the fix.

## Your Task

1. **Create a "bad" container** that uses a `.env` file with a fake API key as an environment variable
2. **Extract the secret** using `docker inspect` -- prove it's visible to anyone who can run Docker commands
3. **Create a "good" container** that uses Docker file-based secrets for the same key
4. **Run the same `docker inspect` command** and show that the secret is gone
5. **Document the difference** -- write a brief comparison showing what each approach exposes

## Success Criteria

- You can extract the secret from the `.env` container using only `docker inspect`
- You CANNOT extract the secret from the Docker Secrets container using `docker inspect`
- Both containers can actually read and use the secret at runtime (it's not just hidden -- it works)
- You can articulate why the second approach is better in 2-3 sentences

---

<details>
<summary>Hint 1: Setting up the "bad" container</summary>

Create a simple `docker-compose-bad.yml` that uses `env_file` or `environment` to pass a secret. Use Alpine with a sleep command so the container stays running while you inspect it. Something like:

```yaml
services:
  leaky:
    image: alpine
    env_file: .env.bad
    command: sleep 3600
```

And a `.env.bad` with `SECRET_API_KEY=super-secret-value-12345`.

</details>

<details>
<summary>Hint 2: The docker inspect command</summary>

The command you want is:

```bash
docker inspect <container_id> --format '{{json .Config.Env}}' | python3 -m json.tool
```

Or just:

```bash
docker inspect <container_id> | grep SECRET
```

Both will show the secret in plain text for the `.env` approach. For the secrets approach, neither will find anything.

</details>

<details>
<summary>Hint 3: The comparison structure</summary>

Run both containers side by side. For each one, try:

1. `docker inspect` -- can you see the secret?
2. `exec env` inside the container -- can the app see the secret?
3. Check `/run/secrets/` inside the secrets container -- is the file there?

The "good" approach should pass test 2 and 3 but fail test 1. The "bad" approach passes all three -- which is the problem.

</details>

---

<details>
<summary>Full Solution</summary>

### Step 1: Create the "bad" deployment

```bash
mkdir -p ~/openclaw/challenge-06
cd ~/openclaw/challenge-06

# The insecure .env file
cat > .env.bad << 'EOF'
SECRET_API_KEY=super-secret-value-12345
EOF

# The insecure compose file
cat > docker-compose-bad.yml << 'EOF'
version: "3.8"
services:
  leaky-app:
    image: alpine:latest
    env_file: .env.bad
    command: ["sh", "-c", "echo 'Running with env vars...' && sleep 3600"]
EOF

docker compose -f docker-compose-bad.yml up -d
```

### Step 2: Extract the secret (the scary part)

```bash
# Method 1: grep through docker inspect
docker inspect $(docker compose -f docker-compose-bad.yml ps -q leaky-app) | grep SECRET_API_KEY

# Method 2: formatted output
docker inspect $(docker compose -f docker-compose-bad.yml ps -q leaky-app) \
  --format '{{range .Config.Env}}{{println .}}{{end}}' | grep SECRET

# Output: SECRET_API_KEY=super-secret-value-12345
# Visible in plain text. Anyone with Docker access sees this.
```

### Step 3: Create the "good" deployment

```bash
# Create secrets
mkdir -p secrets
echo -n "super-secret-value-12345" > secrets/secret_api_key
chmod 700 secrets
chmod 600 secrets/*

# Create entrypoint wrapper
cat > entrypoint-wrapper.sh << 'SCRIPT'
#!/bin/sh
for secret_file in /run/secrets/*; do
  if [ -f "$secret_file" ]; then
    var_name=$(basename "$secret_file" | tr '[:lower:]' '[:upper:]')
    export "$var_name"="$(cat "$secret_file")"
  fi
done
exec "$@"
SCRIPT
chmod +x entrypoint-wrapper.sh

# The secure compose file
cat > docker-compose-good.yml << 'EOF'
version: "3.8"
services:
  secure-app:
    image: alpine:latest
    entrypoint: ["/entrypoint-wrapper.sh"]
    command: ["sh", "-c", "echo 'Running with secrets...' && sleep 3600"]
    volumes:
      - ./entrypoint-wrapper.sh:/entrypoint-wrapper.sh:ro
    secrets:
      - secret_api_key

secrets:
  secret_api_key:
    file: ./secrets/secret_api_key
EOF

docker compose -f docker-compose-good.yml up -d
```

### Step 4: Try to extract the secret

```bash
# Same command as before -- now against the secure container
docker inspect $(docker compose -f docker-compose-good.yml ps -q secure-app) | grep SECRET_API_KEY

# Output: nothing. No matches. The secret is not in Docker's metadata.
```

### Step 5: Prove the secret still works at runtime

```bash
# The app can still access it:
docker compose -f docker-compose-good.yml exec secure-app sh -c 'echo $SECRET_API_KEY'
# Output: super-secret-value-12345

# And it's mounted as a file:
docker compose -f docker-compose-good.yml exec secure-app cat /run/secrets/secret_api_key
# Output: super-secret-value-12345
```

### Step 6: The comparison

| Test | .env approach | Docker Secrets |
|---|---|---|
| `docker inspect` shows secret? | YES -- visible in plain text | NO -- not in metadata |
| App can read the secret? | YES (via env var) | YES (via /run/secrets/ + wrapper) |
| Visible in `docker compose config`? | YES | NO |
| Visible if someone runs `env` on host? | Depends on how it was set | NO |
| Requires root to extract from running process? | NO (just docker access) | YES (/proc requires root) |

**Why Docker Secrets is better, in three sentences:** Environment variables passed via `.env` are stored in Docker's metadata and visible to anyone who can run `docker inspect` -- which is every user in the docker group. Docker file-based secrets mount directly into the container's filesystem, bypassing Docker's metadata entirely. The secret exists only inside the running container, reducing the attack surface from "anyone with Docker access" to "root on the host."

### Cleanup

```bash
docker compose -f docker-compose-bad.yml down
docker compose -f docker-compose-good.yml down
rm -rf ~/openclaw/challenge-06
```

</details>

---

## Bonus Challenge: SOPS + age Encryption

If you finished the main challenge and want to go further, try this:

1. Install `age` and `sops` on your VPS
2. Generate an age keypair
3. Create a `secrets.yaml` file with your placeholder secrets
4. Encrypt it with SOPS
5. Verify you can decrypt it back
6. Write a small shell script that decrypts the SOPS file and writes individual secret files to `secrets/`

No hints for this one. The [SOPS documentation](https://github.com/getsops/sops) and [age documentation](https://github.com/FiloSottile/age) are your guides. This is what production ops feels like -- reading docs and figuring it out.

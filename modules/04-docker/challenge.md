# Challenge 4: Build a Mini Compose Stack

## The Scenario

Your team wants to evaluate SearXNG -- a privacy-respecting, self-hosted search engine -- as a potential tool for your AI agent. Your job: get it running on your VPS with Docker Compose, verify it works, and add a simple status page alongside it. This is a dry run for the real OpenClaw deployment in Module 9, where SearXNG will be one of several services in the stack.

## Your Task

Create a `docker-compose.yml` that:

1. Runs **SearXNG** on `127.0.0.1:8080`
2. Runs a **simple status page** (using nginx with a custom HTML file) on `127.0.0.1:8081`
3. Puts both services on a shared Docker network
4. Uses a volume to persist SearXNG's configuration
5. Uses `restart: unless-stopped` for both services

Then:

6. Start the stack with `docker compose up -d`
7. Test SearXNG with: `curl http://127.0.0.1:8080`
8. Test the status page with: `curl http://127.0.0.1:8081`
9. Check the logs for both services
10. Clean up with `docker compose down`

## Success Criteria

- Both services start without errors
- `curl http://127.0.0.1:8080` returns HTML from SearXNG (a search page)
- `curl http://127.0.0.1:8081` returns your custom status page HTML
- `docker compose ps` shows both services as "running"
- All ports are bound to `127.0.0.1` (not exposed to the internet)

## Starter File

A skeleton compose file is provided at `starter/challenge-compose.yml`. Copy it to your VPS, fill in the TODOs, and rename it to `docker-compose.yml`.

## Hints

<details>
<summary>Hint 1: SearXNG image and ports</summary>

The SearXNG Docker image is `searxng/searxng:latest`. Inside the container, SearXNG listens on port 8080. So your port mapping should map the host's 8080 to the container's 8080.

</details>

<details>
<summary>Hint 2: SearXNG needs a volume</summary>

SearXNG stores its configuration in `/etc/searxng` inside the container. Create a named volume (like `searxng-config`) and mount it there. Without this, your settings reset every time the container restarts.

</details>

<details>
<summary>Hint 3: The status page</summary>

You already built something almost identical in the exercise: an nginx container with a volume-mounted HTML directory. Use the same pattern: create a folder (like `./status-html/`) with an `index.html` inside, and mount it to `/usr/share/nginx/html:ro` in the nginx container. Map the host's 8081 to the container's port 80.

</details>

## Solution

<details>
<summary>Click to reveal the full solution</summary>

### docker-compose.yml

```yaml
services:
  searxng:
    image: searxng/searxng:latest
    container_name: challenge-searxng
    restart: unless-stopped
    ports:
      - "127.0.0.1:8080:8080"
    volumes:
      - searxng-config:/etc/searxng
    networks:
      - stack

  status:
    image: nginx:latest
    container_name: challenge-status
    restart: unless-stopped
    ports:
      - "127.0.0.1:8081:80"
    volumes:
      - ./status-html:/usr/share/nginx/html:ro
    networks:
      - stack

networks:
  stack:

volumes:
  searxng-config:
```

### status-html/index.html

```html
<!DOCTYPE html>
<html>
<head><title>Stack Status</title></head>
<body>
  <h1>Stack Status: Running</h1>
  <p>SearXNG: <a href="http://127.0.0.1:8080">http://127.0.0.1:8080</a></p>
  <p>This page: <a href="http://127.0.0.1:8081">http://127.0.0.1:8081</a></p>
  <p>Last deployed: check 'docker compose ps' for uptime</p>
</body>
</html>
```

### Steps to run it

```bash
# Create the project directory
mkdir -p ~/docker-challenge/status-html
cd ~/docker-challenge

# Create the compose file (paste the YAML above into docker-compose.yml)
nano docker-compose.yml

# Create the status page
nano status-html/index.html

# Start everything
docker compose up -d

# Test SearXNG
curl http://127.0.0.1:8080

# Test the status page
curl http://127.0.0.1:8081

# Check status
docker compose ps

# Check logs
docker compose logs -f

# When you're done, clean up
docker compose down
```

### Why this approach?

We're using the same patterns from the exercise -- named volumes, `127.0.0.1` port binding, a shared network, `restart: unless-stopped` -- because these are the exact patterns used in the real OpenClaw deployment. The SearXNG service here is literally the same one you'll use in production.

The status page is a simple stand-in for a real monitoring dashboard. In Module 10, we'll replace it with Uptime Kuma, which does the same job but with actual health checks and alerts.

### What about alternatives?

You could skip the shared network and let Docker Compose create a default one (it does this automatically). That works fine for small stacks. We're being explicit about the network because in the real deployment, you'll want to control which services can talk to each other -- and that starts with naming your networks.

</details>

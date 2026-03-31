# Challenge 2: Build a Three-Service Compose Stack

## The Scenario

You've mastered two services. Now let's level up. Your task: build a Docker Compose file with three services, a shared network, and a named volume. This is the exact pattern you'll use for every deployment in this course -- just with different images.

## Your Task

Create a `docker-compose.yml` that runs:

1. **nginx** -- a web server on `127.0.0.1:8080` serving a custom HTML page
2. **whoami** -- the Traefik debug service on `127.0.0.1:8081`
3. **httpbin** -- an HTTP testing service on `127.0.0.1:8082` (image: `kennethreitz/httpbin`)

Requirements:

- All three services on a shared network called `playground`
- nginx should use a bind mount to serve custom HTML (read-only)
- Use a named volume called `nginx-cache` mounted at `/var/cache/nginx` on the nginx service
- All ports bound to `127.0.0.1` (security habit!)
- `restart: unless-stopped` on all services

Then:

4. Start the stack with `docker compose up -d`
5. Test all three services:
   - `curl http://127.0.0.1:8080` (your custom page)
   - `curl http://127.0.0.1:8081` (whoami info)
   - `curl http://127.0.0.1:8082/get` (httpbin echo)
6. Shell into the nginx container and verify it can reach whoami: `curl http://whoami:80`
7. Check the logs for all services
8. Clean up with `docker compose down`

## Success Criteria

- All three services start without errors
- Each service responds correctly on its port
- Containers on the `playground` network can reach each other by service name
- All ports are bound to `127.0.0.1`
- The named volume is declared and mounted

## Starter File

A skeleton compose file is provided at `starter/challenge-compose.yml`. Copy it, fill in the TODOs, and rename it to `docker-compose.yml`.

## Hints

<details>
<summary>Hint 1: httpbin image and ports</summary>

The httpbin image is `kennethreitz/httpbin`. Inside the container, it listens on port 80. So your port mapping should be `127.0.0.1:8082:80`.

</details>

<details>
<summary>Hint 2: Testing container-to-container networking</summary>

Once you shell into a container with `docker compose exec web bash`, you can use `curl` to hit other services by their service name. If curl isn't installed in the container, try: `apt-get update && apt-get install -y curl` (you're inside the container, so this doesn't affect your host).

</details>

<details>
<summary>Hint 3: Named volume syntax</summary>

A named volume is declared in two places: in the service's `volumes:` list (e.g., `nginx-cache:/var/cache/nginx`) and at the bottom of the file under a top-level `volumes:` key.

</details>

## Bonus Challenge: Run a Real Search Engine

If you want to go further, try running **SearXNG** -- a privacy-respecting, self-hosted search engine. This is the same tool that OpenClaw can use as a search backend later in the course.

Add a fourth service to your stack:

```yaml
  searxng:
    image: searxng/searxng:latest
    container_name: challenge-searxng
    restart: unless-stopped
    ports:
      - "127.0.0.1:8083:8080"
    volumes:
      - searxng-config:/etc/searxng
    networks:
      - playground
```

Don't forget to declare `searxng-config` under `volumes:` at the bottom of your file.

Start the stack, then `curl http://127.0.0.1:8083`. You should get SearXNG's search page HTML back. You just self-hosted a search engine in about 10 seconds. Not bad.

## Solution

<details>
<summary>Click to reveal the full solution</summary>

### docker-compose.yml

```yaml
services:
  web:
    image: nginx:latest
    container_name: challenge-web
    restart: unless-stopped
    ports:
      - "127.0.0.1:8080:80"
    volumes:
      - ./html:/usr/share/nginx/html:ro
      - nginx-cache:/var/cache/nginx
    networks:
      - playground

  whoami:
    image: traefik/whoami:latest
    container_name: challenge-whoami
    restart: unless-stopped
    ports:
      - "127.0.0.1:8081:80"
    networks:
      - playground

  httpbin:
    image: kennethreitz/httpbin
    container_name: challenge-httpbin
    restart: unless-stopped
    ports:
      - "127.0.0.1:8082:80"
    networks:
      - playground

networks:
  playground:

volumes:
  nginx-cache:
```

### html/index.html

```html
<!DOCTYPE html>
<html>
<head><title>Three-Service Stack</title></head>
<body>
  <h1>The Three-Service Stack Works!</h1>
  <p>nginx: <a href="http://127.0.0.1:8080">:8080</a></p>
  <p>whoami: <a href="http://127.0.0.1:8081">:8081</a></p>
  <p>httpbin: <a href="http://127.0.0.1:8082/get">:8082/get</a></p>
</body>
</html>
```

### Steps to run it

```bash
mkdir -p ~/docker-challenge/html
cd ~/docker-challenge

# Create docker-compose.yml (paste the YAML above)
# Create html/index.html (paste the HTML above)

docker compose up -d
curl http://127.0.0.1:8080
curl http://127.0.0.1:8081
curl http://127.0.0.1:8082/get

# Test container-to-container networking
docker compose exec web bash
# Inside the container:
apt-get update && apt-get install -y curl
curl http://whoami:80
exit

# Check logs
docker compose logs

# Clean up
docker compose down
```

</details>

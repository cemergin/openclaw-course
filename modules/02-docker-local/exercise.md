# Exercise 2: Getting Your Hands on Docker

## What We're Doing

We're going to run some containers, build a multi-service Docker Compose stack, and get comfortable with the commands you'll use for the rest of this course. By the end, you'll have two services running side by side and you'll know how to start, stop, inspect, and debug them.

## Prerequisites

- Docker installed and running on your machine (from the Speed Run)
- A terminal open and ready to go

**Self-check:** Run `docker --version`. See a version number? Let's go.

## Part 1: Run Something Useful

A "Hello from Docker!" message is nice, but let's run an actual web server.

**1. Start an nginx container**

```bash
docker run -d --name my-nginx -p 127.0.0.1:8080:80 nginx
```

Let's break this down:
- `-d` -- run detached (in the background)
- `--name my-nginx` -- give it a human-readable name
- `-p 127.0.0.1:8080:80` -- map port 8080 on localhost to port 80 inside the container
- `nginx` -- the image to use

**Before you hit enter:** If you've never pulled the nginx image before, what do you think Docker will do first?

**2. Check that it's running**

```bash
docker ps
```

You should see your `my-nginx` container in the list with status "Up."

**3. Test it with curl (or your browser)**

```bash
curl http://127.0.0.1:8080
```

Or just open `http://localhost:8080` in your browser. You should get nginx's default welcome page. You just ran a web server in about 3 seconds, without installing anything on your system.

**4. Check the logs**

```bash
docker logs my-nginx
```

You'll see nginx's access log, including the request you just made.

**5. Check resource usage**

```bash
docker stats --no-stream
```

The `--no-stream` flag gives you a single snapshot instead of a live updating view. Notice how little CPU and RAM the container uses.

**6. Clean up**

```bash
docker stop my-nginx
docker rm my-nginx
```

Or do both in one shot:

```bash
docker rm -f my-nginx
```

Run `docker ps -a` to confirm it's gone. The `-a` flag shows stopped containers too -- without it you'd only see running ones.

## Part 2: Docker Compose -- Two Services at Once

Now let's graduate from single containers to a multi-service stack. We're going to run nginx (a web server) and whoami (a tiny debug service from Traefik) side by side.

**7. Create a project directory**

```bash
mkdir -p ~/docker-exercise
cd ~/docker-exercise
```

**8. Copy the starter file**

Copy the file from `starter/docker-compose.yml` in this module to `~/docker-exercise/docker-compose.yml`. Or create it yourself with the following content:

```yaml
services:
  web:
    image: nginx:latest
    container_name: exercise-web
    restart: unless-stopped
    ports:
      - "127.0.0.1:8080:80"
    volumes:
      - ./html:/usr/share/nginx/html:ro
    networks:
      - frontend

  whoami:
    image: traefik/whoami:latest
    container_name: exercise-whoami
    restart: unless-stopped
    ports:
      - "127.0.0.1:8081:80"
    networks:
      - frontend

networks:
  frontend:
```

Take a moment to read through it. Two services, both on the `frontend` network. The `web` service has a volume mount. Both bind to `127.0.0.1`.

**9. Create a custom web page**

```bash
mkdir -p ~/docker-exercise/html
```

Create `~/docker-exercise/html/index.html` with your favorite text editor:

```html
<!DOCTYPE html>
<html>
<head><title>Docker Works!</title></head>
<body>
  <h1>Hello from Docker Compose</h1>
  <p>If you can see this, your nginx container is serving files from a volume.</p>
</body>
</html>
```

**10. Start the stack**

```bash
cd ~/docker-exercise
docker compose up -d
```

**Before you hit enter:** You have two services defined. How many containers will Docker create? What about the network?

You should see Docker pull any missing images, create the network, and start both containers.

**11. Test both services**

```bash
curl http://127.0.0.1:8080
curl http://127.0.0.1:8081
```

The first should show your custom HTML page. The second runs `whoami` -- a tiny service that responds with information about the request it received (hostname, IP, headers). Super handy for debugging.

**12. Check the status of your compose stack**

```bash
docker compose ps
```

Both services should show as "running."

**13. Follow the logs**

```bash
docker compose logs -f
```

Now open another terminal and run `curl http://127.0.0.1:8080` a few times. Watch the logs update in real time. Press `Ctrl+C` to stop following.

You can also follow logs for just one service:

```bash
docker compose logs -f web
```

**14. Shell into a running container**

```bash
docker compose exec web bash
```

You're now *inside* the nginx container. Try:

```bash
cat /usr/share/nginx/html/index.html
hostname
exit
```

You should see your custom HTML file and the container's hostname. This is how you debug containers -- get inside and look around.

**15. Inspect a container**

```bash
docker inspect exercise-web
```

That's a wall of JSON, but scroll through it. You'll see network settings, volume mounts, environment variables, and more. This is where Docker stores everything about a running container.

Want something more focused? Try:

```bash
docker inspect exercise-web --format '{{.NetworkSettings.Networks}}'
```

**16. Explore the volume mount**

While the stack is running, edit `html/index.html` on your host machine. Change the `<h1>` text to something different. Now curl the page again:

```bash
curl http://127.0.0.1:8080
```

Did it update without restarting the container? It should -- that's the bind mount in action. The container reads directly from your host's filesystem.

**17. Bring it all down**

```bash
docker compose down
```

This stops and removes all containers and removes the network. Your files in `~/docker-exercise/html/` are still there because they live on the host, not inside the container.

Verify:

```bash
docker ps -a
```

No exercise containers should remain.

## What Just Happened?

You just:

- Ran a standalone container (nginx) and tested it
- Created a Docker Compose file with two services, a volume mount, and a custom network
- Used `docker compose up`, `down`, `ps`, `logs`, and `exec`
- Practiced the `127.0.0.1:` port binding pattern
- Explored live volume mounts and container inspection

Every single one of these skills transfers directly to deploying OpenClaw. The compose file we build in Module 3 is the real thing, and the commands are identical.

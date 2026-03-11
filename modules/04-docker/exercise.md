# Exercise 4: Getting Your Hands on Docker

## What We're Doing

We're going to install Docker on your VPS, run a few containers to build your muscle memory, then create a Docker Compose stack with two services. By the end, you'll be comfortable starting, stopping, inspecting, and debugging containers.

## Prerequisites

- SSH access to your VPS as the `openclaw` user (from Module 3)
- Your VPS should be running Ubuntu 22.04 on Lightsail (from Module 2)

## Part 1: Install Docker

**1. SSH into your VPS**

```bash
ssh openclaw@<your-server-ip>
```

**2. Install Docker using the official convenience script**

```bash
curl -fsSL https://get.docker.com | sudo bash
```

This downloads and runs Docker's official install script. It detects your Linux distribution and installs the right version. This is Docker's recommended method for simple setups.

> **Pro tip:** Normally, piping a script from the internet into `bash` is something to be cautious about. In this case, it's Docker's official script hosted on their domain. But it's a good habit to be skeptical of `curl | bash` patterns in general.

**3. Add your user to the `docker` group**

```bash
sudo usermod -aG docker openclaw
```

This lets the `openclaw` user run Docker commands without `sudo`. The change won't take effect until you log out and back in.

**4. Log out and back in**

```bash
exit
ssh openclaw@<your-server-ip>
```

**5. Verify Docker is installed and your user can use it**

```bash
docker --version
```

You should see something like `Docker version 27.x.x`. The exact version doesn't matter as long as it's recent.

**6. Run the hello-world test**

```bash
docker run hello-world
```

**Before you hit enter:** What do you think will happen? Docker doesn't have the `hello-world` image locally yet.

You should see Docker pull the image, then print a "Hello from Docker!" message. That message means: Docker is installed, your user has permission to use it, and container execution is working.

## Part 2: Run Something Useful

A "Hello from Docker!" message is nice, but let's run an actual web server.

**7. Start an nginx container**

```bash
docker run -d --name my-nginx -p 127.0.0.1:8080:80 nginx
```

Let's break this down:
- `-d` -- run detached (in the background)
- `--name my-nginx` -- give it a human-readable name
- `-p 127.0.0.1:8080:80` -- map port 8080 on localhost to port 80 inside the container
- `nginx` -- the image to use

**8. Check that it's running**

```bash
docker ps
```

You should see your `my-nginx` container in the list with status "Up."

**9. Test it with curl**

```bash
curl http://127.0.0.1:8080
```

You should get a page of HTML back -- nginx's default welcome page. You just ran a web server in about 3 seconds, without installing anything on your system.

**10. Check the logs**

```bash
docker logs my-nginx
```

You'll see nginx's access log, including the request you just made with curl.

**11. Check resource usage**

```bash
docker stats --no-stream
```

The `--no-stream` flag gives you a single snapshot instead of a live updating view. You'll see how much CPU and RAM your container is using (spoiler: almost nothing).

**12. Clean up**

```bash
docker stop my-nginx
docker rm my-nginx
```

Or do both in one shot:

```bash
docker rm -f my-nginx
```

Run `docker ps -a` to confirm it's gone. The `-a` flag shows stopped containers too -- without it you'd only see running ones.

## Part 3: Docker Compose

Now let's graduate from single containers to a multi-service stack.

**13. Create a project directory and compose file**

```bash
mkdir -p ~/docker-exercise
cd ~/docker-exercise
```

Create a file called `docker-compose.yml` with the following content. You can use `nano docker-compose.yml` to create and edit it:

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

> **Pro tip:** The `:ro` on the volume mount means "read-only." The container can read the files but can't modify them. Good practice for serving static content.

**14. Create a custom web page**

```bash
mkdir -p ~/docker-exercise/html
```

Create `~/docker-exercise/html/index.html`:

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

**15. Start the stack**

```bash
cd ~/docker-exercise
docker compose up -d
```

**Before you hit enter:** You have two services defined. What do you think Docker Compose will do with each of them?

You should see both services start. Docker Compose creates the network, pulls any missing images, and starts both containers.

**16. Test both services**

```bash
curl http://127.0.0.1:8080
curl http://127.0.0.1:8081
```

The first should show your custom HTML page. The second runs `whoami` -- a tiny service that responds with information about the request it received (hostname, IP, headers). It's handy for debugging.

**17. Check the status of your compose stack**

```bash
docker compose ps
```

Both services should show as "running."

**18. Follow the logs**

```bash
docker compose logs -f
```

Open a second SSH session and run `curl http://127.0.0.1:8080` a few times. Watch the logs update in real time. Press `Ctrl+C` to stop following.

**19. Shell into a running container**

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

**20. Bring it all down**

```bash
docker compose down
```

This stops and removes all containers, and removes the network. Your files in `~/docker-exercise/html/` are still there because they live on the host (the volume mount), not inside the container.

Verify everything is cleaned up:

```bash
docker ps -a
```

No exercise containers should remain.

## What Just Happened?

You just:

- Installed Docker on your VPS
- Ran a standalone container (nginx) and tested it
- Created a Docker Compose file with two services, a volume mount, and a custom network
- Used `docker compose up`, `down`, `ps`, `logs`, and `exec`
- Practiced the `127.0.0.1:` port binding pattern for security

Every single one of these skills transfers directly to deploying OpenClaw. The compose file we'll build in Module 9 is bigger, but the commands are identical.

## Try This (Optional Experiments)

- **Edit and refresh:** While the stack is running, edit `html/index.html` on the host. Then curl the page again. Does it update without restarting the container? (It should -- that's the volume mount in action.)
- **Stop just one service:** Run `docker compose stop whoami` and verify with `docker compose ps`. The web service should still be running.
- **Check images on disk:** Run `docker images` to see what images Docker downloaded. Notice how they take up space. You can clean up unused images later with `docker image prune`.
- **Inspect a container:** Run `docker inspect exercise-web` while the stack is up. It's a wall of JSON, but scroll through it -- you'll see network settings, volume mounts, environment variables, and more. This is where Docker stores everything about a running container.

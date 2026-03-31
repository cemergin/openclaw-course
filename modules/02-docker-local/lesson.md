# Lesson 2: Docker on Your Machine

## The Problem With Installing Stuff Directly

Have you ever installed a bunch of software on your computer, then six months later nothing works right because Python 3.8 is fighting with Python 3.11, some library got updated and broke something else, and you're scared to uninstall anything because you're not sure what depends on what?

That's bare metal. You install things directly on the operating system, and over time your machine turns into a haunted house where nothing is where you expect it and mysterious processes run in the background.

There has to be a better way. And there is.

## The Shipping Container Analogy

In the 1950s, shipping goods around the world was chaos. Every port had different equipment. Loading a ship took days. Fragile stuff got broken. Weird-shaped cargo was a nightmare.

Then someone invented the *shipping container* -- a standard-sized metal box. Didn't matter what was inside: TVs, bananas, car parts. The box was always the same size, fit on the same trucks, loaded with the same cranes. Suddenly, global shipping became fast, cheap, and reliable.

Docker containers did the same thing for software.

A Docker container is a standardized box for your application. Inside the box: your app, its dependencies, its configuration, everything it needs to run. Outside the box: your computer doesn't know or care what's inside. It just runs boxes.

## Three Ways to Run Software

Let's compare the three main approaches:

**Bare metal** -- install directly on the machine. It's like cooking in someone else's kitchen: your ingredients are mixed with theirs, you argue about oven temperature, and cleaning up is a nightmare. Fast, but messy.

**Virtual machines (VMs)** -- each app gets its own complete fake computer, with its own operating system. It's like building a separate kitchen for every meal. Works great, but heavy. A VM might take 30 seconds to boot and use 1 GB of RAM just for the operating system before your app even starts.

**Containers** -- your app gets its own isolated space, but shares the host's operating system kernel. It's like having your own prep station in a shared kitchen: your tools, your ingredients, your cutting board, but you're all using the same stove and oven. Starts in milliseconds, uses almost no overhead.

For our project, containers are the obvious choice. We want to run OpenClaw (and maybe other services alongside it) in a way that's clean, reproducible, and easy to move from your laptop to a server.

## Images vs Containers

This distinction trips people up, so let's nail it:

- An **image** is a recipe. It's a read-only template that describes what goes in the box. "Start with Ubuntu, install Node.js, copy my app code, set the startup command."
- A **container** is a cooked dish. It's a running instance created from that recipe. You can have five containers all running from the same image, just like you can cook five batches of cookies from the same recipe.

When you do `docker run nginx`, Docker takes the `nginx` image (the recipe), creates a container from it (cooks the dish), and starts it running.

Images live on Docker Hub, which is basically the app store for container images. When you reference an image like `nginx` or `traefik/whoami`, Docker downloads it from there.

## Docker Compose: The Orchestra Conductor

Running one container is easy. But real applications have multiple services that need to work together. You *could* start each one with a separate `docker run` command, remembering all the flags and options each time. But that's tedious and error-prone.

Docker Compose lets you describe your entire stack in a single YAML file called `docker-compose.yml`. Here's what one looks like:

```yaml
services:
  web:
    image: nginx:latest
    ports:
      - "127.0.0.1:8080:80"

  database:
    image: postgres:16
    volumes:
      - db-data:/var/lib/postgresql/data

volumes:
  db-data:
```

Then you just run:

```bash
docker compose up -d
```

And everything starts. One file, one command. That's it.

The `-d` flag means "detached" -- run in the background so you get your terminal back.

Here's the key insight that makes this entire course possible: **the same `docker-compose.yml` works on your laptop AND the server.** That's the magic of containers. You build it locally, test it locally, then copy the file to your VPS and run the exact same command. Same file, same result. No "but it works on my machine" problems.

## The Anatomy of a Compose File

Let's break down what goes in that YAML file:

### Services

Each service is one container. The name you give it (like `web` or `database`) becomes its hostname on the internal network -- more on that in a moment.

```yaml
services:
  myapp:
    image: some-image:latest
    container_name: myapp
    restart: unless-stopped
```

The `restart: unless-stopped` bit means Docker will automatically restart this container if it crashes, or when the machine reboots. The only way it stays stopped is if you explicitly stop it yourself. This is what you want for services that should always be running.

### Volumes: Data That Survives

Containers are *ephemeral* by default. When a container dies, everything inside it dies too. That's great for the app code (just start a fresh one from the image), but terrible for data you want to keep -- like a database, config files, or conversation history.

Volumes are the solution. They're storage that gets mounted inside the container. The container sees them as normal directories, but the data persists even when the container is removed.

There are two kinds:

**Named volumes** -- Docker manages the storage location for you:

```yaml
services:
  database:
    image: postgres:16
    volumes:
      - db-data:/var/lib/postgresql/data

volumes:
  db-data:
```

The `db-data:/var/lib/postgresql/data` line means: "Mount the volume called `db-data` at the path `/var/lib/postgresql/data` inside the container." You declare the volume at the bottom of the file.

**Bind mounts** -- you choose the exact folder on your host:

```yaml
services:
  web:
    image: nginx:latest
    volumes:
      - ./html:/usr/share/nginx/html:ro
```

This maps the `./html` folder (relative to your compose file) into the container. The `:ro` suffix means "read-only" -- the container can read the files but can't modify them. Good practice for serving static content.

### Networks: How Containers Talk

Here's something that surprises people: containers in the same Docker Compose file can talk to each other using the service name as a hostname.

If you have a service called `whoami` and another called `web`, then `web` can reach `whoami` at `http://whoami:80`. No IP addresses, no configuration. Docker's internal DNS handles it.

```yaml
services:
  web:
    image: nginx:latest
    networks:
      - frontend

  whoami:
    image: traefik/whoami:latest
    networks:
      - frontend

networks:
  frontend:
```

Both services are on the `frontend` network, so they can find each other by name. Services on different networks can't see each other -- useful for isolation.

> **Pro tip:** Docker Compose actually creates a default network for all services in a file, so you don't *have* to define one explicitly. But being explicit about networks is a good habit -- especially when your stack grows and you want to control which services can talk to each other.

### Ports: The Security-Critical Part

Port mapping connects a port inside the container to a port on your host. But *how* you map it matters a lot for security.

```yaml
# DANGEROUS -- accessible from the entire internet (when on a server)
ports:
  - "3000:3000"

# SAFE -- only accessible from the machine itself
ports:
  - "127.0.0.1:3000:3000"
```

See that `127.0.0.1:` prefix? That's the difference between "anyone on the internet can reach this" and "only this machine can reach this."

### Why This Matters: Docker Bypasses Your Firewall

This is one of those things that bites people hard. On Linux servers, you might set up a firewall (like UFW) and feel safe. But here's the nasty surprise: **Docker manipulates iptables directly, bypassing UFW entirely.**

That means if you write `ports: - "3000:3000"` without the `127.0.0.1:` prefix, Docker punches a hole straight through your firewall and exposes that port to the entire internet. Your UFW rules? Docker doesn't care. It goes around them.

This has been a known issue for years, and it's caught countless people off guard. The fix is simple: **always use the `127.0.0.1:` prefix for every port mapping.** This binds the port to the loopback interface only, so only processes on the same machine can reach it.

```yaml
# Always do this:
ports:
  - "127.0.0.1:8080:80"

# Never do this (unless you have a very specific reason):
ports:
  - "8080:80"
```

On your local machine, this distinction matters less (your laptop isn't usually directly accessible from the internet). But we're building habits for deployment, and this habit will save you when we move to a VPS.

> **Rule of thumb:** If you see a port mapping in this course without `127.0.0.1:`, it's a typo. Every port binding should have it.

## Essential Docker Commands

You'll use these constantly. They're worth memorizing:

```bash
# Container basics
docker ps                     # What's running right now?
docker ps -a                  # What about stopped containers too?
docker logs <container>       # Show me what happened
docker logs -f <container>    # Follow the logs live (Ctrl+C to stop)
docker stats                  # Live CPU/RAM/network usage
docker inspect <container>    # Everything Docker knows about a container (JSON)

# Docker Compose (run from the directory with your docker-compose.yml)
docker compose up -d          # Start everything
docker compose down           # Stop and remove everything
docker compose ps             # Status of compose services
docker compose logs -f        # Follow all logs
docker compose logs -f web    # Follow logs for just one service
docker compose exec web bash  # Open a shell inside a running container
docker compose pull           # Download latest images
docker compose pull && docker compose up -d  # Update everything
```

> **Pro tip:** `docker compose exec <service> bash` is your debugging superpower. It opens a shell *inside* a running container so you can poke around, check files, test network connectivity, whatever you need. It's like SSH-ing into a container.

## The Bigger Picture

Here's why this matters for this course specifically: everything we deploy -- OpenClaw, monitoring tools, tunnels, search engines -- runs in Docker containers managed by Docker Compose. One YAML file, one command to start, one command to stop.

When there's an update, you pull the new images and restart. When something breaks, you check the logs. When you want to move to a different server, you copy the compose file and your data, and you're done.

The same `docker-compose.yml` you build on your laptop in the next module is the same file you'll deploy to your VPS. That's the whole point of containers. Build once, run anywhere.

Let's put it into practice.

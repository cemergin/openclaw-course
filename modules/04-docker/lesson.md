# Lesson 4: Containers -- Your Apps in Boxes

## The Problem With Installing Stuff Directly

Have you ever installed a bunch of software on a computer, then six months later nothing works right because Python 3.8 is fighting with Python 3.11, some library got updated and broke something else, and you're scared to uninstall anything because you're not sure what depends on what?

That's bare metal. You install things directly on the operating system, and over time your server turns into a haunted house where nothing is where you expect it and mysterious processes run in the background.

There has to be a better way. And there is.

## The Shipping Container Analogy

In the 1950s, shipping goods around the world was chaos. Every port had different equipment. Loading a ship took days. Fragile stuff got broken. Weird-shaped cargo was a nightmare.

Then someone invented the *shipping container* -- a standard-sized metal box. Didn't matter what was inside: TVs, bananas, car parts. The box was always the same size, fit on the same trucks, loaded with the same cranes. Suddenly, global shipping became fast, cheap, and reliable.

Docker containers did the same thing for software.

A Docker container is a standardized box for your application. Inside the box: your app, its dependencies, its configuration, everything it needs to run. Outside the box: your server doesn't know or care what's inside. It just runs boxes.

## Three Ways to Run Software

Let's compare the three main approaches:

**Bare metal** -- install directly on the server. It's like cooking in someone else's kitchen: your ingredients are mixed with theirs, you argue about oven temperature, and cleaning up is a nightmare. Fast, but messy.

**Virtual machines (VMs)** -- each app gets its own complete fake computer, with its own operating system. It's like building a separate kitchen for every meal. Works great, but heavy. A VM might take 30 seconds to boot and use 1 GB of RAM just for the operating system before your app even starts.

**Containers** -- your app gets its own isolated space, but shares the host's operating system kernel. It's like having your own prep station in a shared kitchen: your tools, your ingredients, your cutting board, but you're all using the same stove and oven. Starts in milliseconds, uses almost no overhead.

For our project, containers are the obvious choice. We're running multiple services (OpenClaw, a search engine, a monitoring tool, a tunnel) and we need them to be isolated, easy to start/stop, and easy to update.

## Images vs Containers

This distinction trips people up, so let's nail it:

- An **image** is a recipe. It's a read-only template that describes what goes in the box. "Start with Ubuntu, install Node.js, copy my app code, set the startup command."
- A **container** is a cooked dish. It's a running instance created from that recipe. You can have five containers all running from the same image, just like you can cook five batches of cookies from the same recipe.

When you do `docker run nginx`, Docker takes the `nginx` image (the recipe), creates a container from it (cooks the dish), and starts it running.

Images live on Docker Hub, which is basically the app store for container images. When you reference an image like `nginx` or `searxng/searxng`, Docker downloads it from there.

## Docker Compose: The Orchestra Conductor

Running one container is easy. But real applications have multiple services that need to work together. OpenClaw, for example, needs:

- The OpenClaw app itself
- SearXNG (a private search engine)
- Cloudflared (a tunnel to Cloudflare)
- Uptime Kuma (monitoring)

You *could* start each one with a separate `docker run` command, remembering all the flags and options each time. But that's tedious and error-prone.

Docker Compose lets you describe your entire stack in a single YAML file called `docker-compose.yml`. Here's what one looks like (simplified):

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

## The Anatomy of a Compose File

Let's break down what goes in that YAML file:

### Services

Each service is one container. The name you give it (like `web` or `database`) becomes its hostname on the internal network -- more on that in a moment.

```yaml
services:
  searxng:
    image: searxng/searxng:latest
    container_name: searxng
    restart: unless-stopped
```

The `restart: unless-stopped` bit means Docker will automatically restart this container if it crashes, or when the server reboots. The only way it stays stopped is if you explicitly stop it yourself. This is what you want for services that should always be running.

### Volumes: Data That Survives

Containers are *ephemeral* by default. When a container dies, everything inside it dies too. That's great for the app code (just start a fresh one from the image), but terrible for data you want to keep -- like a database, config files, or logs.

Volumes are the solution. They're folders on your host machine that get mounted inside the container. The container sees them as normal directories, but the data actually lives on your server's disk and persists even when the container is removed.

```yaml
services:
  database:
    image: postgres:16
    volumes:
      - db-data:/var/lib/postgresql/data

volumes:
  db-data:
```

The `db-data:/var/lib/postgresql/data` line means: "Mount the volume called `db-data` at the path `/var/lib/postgresql/data` inside the container." Postgres writes its data to that path, and it ends up safely stored in the volume on your host.

### Networks: How Containers Talk

Here's something that surprises people: containers in the same Docker Compose file can talk to each other using the service name as a hostname.

If you have a service called `searxng` and another called `openclaw`, then OpenClaw can reach SearXNG at `http://searxng:8080`. No IP addresses, no configuration. Docker's internal DNS handles it.

```yaml
services:
  openclaw:
    image: openclaw/openclaw:latest
    networks:
      - internal

  searxng:
    image: searxng/searxng:latest
    networks:
      - internal

networks:
  internal:
```

Both services are on the `internal` network, so they can find each other by name. Services on different networks can't see each other -- this is useful for isolation.

### Ports: The Security-Critical Part

Port mapping connects a port inside the container to a port on your host. But *how* you map it matters a lot for security.

```yaml
# DANGEROUS -- accessible from the entire internet
ports:
  - "3000:3000"

# SAFE -- only accessible from the VPS itself
ports:
  - "127.0.0.1:3000:3000"
```

See that `127.0.0.1:` prefix? That's the difference between "anyone on the internet can reach this" and "only the server itself can reach this."

`127.0.0.1` is the loopback address -- it means "this machine only." When you bind a port to `127.0.0.1`, only processes running on the same server (or a tunnel like Cloudflare Tunnel) can access it. The outside world can't touch it.

> **Pro tip:** In our setup, we *always* use the `127.0.0.1:` prefix for every port mapping. Cloudflare Tunnel handles getting external traffic to our services safely. If you forget the prefix, you've just put a service on the public internet. This matters so much that we'll remind you about it approximately forty-seven more times in this course.

## The Bigger Picture

Here's why Docker matters for this project specifically: OpenClaw's entire deployment is a single `docker-compose.yml` file. When we get to Module 9, you'll build a compose file with four or five services, and the whole thing will start with one command. When there's an update, you pull the new images and restart. When something breaks, you check the logs. When you want to move to a different server, you copy the compose file and your data, and you're done.

This is the power of containers. Your entire infrastructure is defined in a text file that you can version control, share, and reproduce exactly.

## Essential Docker Commands

You'll use these daily. They're worth memorizing:

```bash
# Docker basics
docker ps                     # What's running right now?
docker ps -a                  # What about stopped containers too?
docker logs <container>       # Show me what happened
docker logs -f <container>    # Follow the logs live (Ctrl+C to stop)
docker stats                  # Live CPU/RAM/network usage

# Docker Compose (run from the directory with your docker-compose.yml)
docker compose up -d          # Start everything
docker compose down           # Stop everything
docker compose ps             # Status of compose services
docker compose logs -f        # Follow all logs
docker compose logs -f web    # Follow logs for just one service
docker compose exec web bash  # Open a shell inside a running container
docker compose pull           # Download latest images
docker compose pull && docker compose up -d  # Update everything
```

> **Pro tip:** `docker compose exec <service> bash` is your debugging superpower. It opens a shell *inside* a running container so you can poke around, check files, test network connectivity, whatever you need. It's like SSH-ing into a container.

## What We Didn't Cover (And That's Fine)

Docker is enormous. We skipped Dockerfiles (building your own images), multi-stage builds, Docker Swarm, container registries, health checks, and about fifty other things. We don't need them. We're using pre-built images and Docker Compose, which is exactly the right level for deploying and managing applications. If you ever need to build your own images, you'll have the foundation to learn that later.

Right now, you know enough to run, manage, and debug containerized applications. That's the goal. Let's put it into practice.

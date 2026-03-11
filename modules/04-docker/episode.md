# Episode 4: Containers -- Your Apps in Boxes

## Docker and Docker Compose for Humans

### In This Episode

Instead of installing software directly onto your server (where it gets tangled up with everything else like a junk drawer), we're going to use containers -- standardized, self-contained boxes that keep everything neat and disposable. You'll install Docker on your VPS, run your first container, and learn Docker Compose, the tool that lets you describe your entire application stack in one file. By the end, you'll have the skills to run, inspect, debug, and clean up containerized apps -- which is exactly how we'll deploy OpenClaw in Module 9.

### Key Concepts

- **Containers vs VMs vs bare metal** -- three ways to run software, one clear winner for our use case
- **Images vs containers** -- blueprints vs running instances (recipes vs cooked dishes)
- **Docker Compose** -- one YAML file to rule them all, one command to start/stop everything
- **Volumes** -- persistent data that survives when containers die
- **Networks** -- how containers find and talk to each other by name
- **Port mapping** -- connecting the inside of a container to the outside world (with a security twist)

### Prerequisites

You should have completed Modules 2 and 3. You need a running VPS with SSH access and a dedicated `openclaw` user.

**Self-check:** Can you SSH into your server as the `openclaw` user and run `sudo apt update` without errors? You're ready.

### Builds On

- **Module 2: Your Computer in the Sky** -- you have a VPS running on Lightsail
- **Module 3: Remote Control -- SSH and Linux Basics** -- you can connect to it, navigate the filesystem, and install packages

### What's Next

In **Module 5: The Lethal Trifecta**, we'll learn about security -- the three things that get servers owned and how to prevent all of them. The Docker knowledge you build here is essential, because every service we secure in the rest of the course runs inside a container.

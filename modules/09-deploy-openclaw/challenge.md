# Challenge 9: Make It Yours

## The Scenario

Your AI agent is running. Messages go in, responses come out. But right now it's using default settings -- the AI equivalent of a new phone with no apps installed and the factory wallpaper still on.

Your task: customize your OpenClaw deployment so it works the way *you* want it to. Change the AI model, tweak the system prompt, verify that web search actually works through SearXNG, practice the operational commands until they're muscle memory, and understand what your stack is doing with your server's resources.

This isn't a single task with one correct answer -- it's a series of customizations that make this deployment genuinely yours.

## Tasks

### Task 1: Customize the System Prompt

OpenClaw has a system prompt that shapes how your AI agent responds. Find it and make it your own.

**Success criteria:**
- You've located the system prompt configuration (hint: it's in the `config/` directory)
- You've edited it to give your agent a personality, specific instructions, or context about how you want it to behave
- You've restarted OpenClaw and verified the new behavior by sending a test message

### Task 2: Verify SearXNG Integration

You deployed SearXNG, but does OpenClaw actually use it? Let's find out.

**Success criteria:**
- You've sent a message that requires a web search (e.g., "What happened in the news today?")
- You can see in the OpenClaw logs that it queried SearXNG
- You've also queried SearXNG directly from the command line to verify it's returning results

### Task 3: Explore Model Options

Claude Sonnet is the default, but you have options. Maybe you want Claude Haiku for faster, cheaper responses. Maybe you want to try a different model for certain tasks.

**Success criteria:**
- You've checked what models are available in your OpenClaw config
- You've switched to a different model (even temporarily) and sent a test message
- You can articulate the trade-off: faster/cheaper vs smarter/more expensive

### Task 4: Master the Operations

Run through every daily operations command until you don't need to look them up.

**Success criteria:**
- You've practiced: `docker compose ps`, `docker compose logs -f openclaw`, `docker compose restart openclaw`, `docker compose down`, `docker compose up -d`, `docker compose pull && docker compose up -d`, `docker stats`
- You can check resource usage and know roughly what's normal for your stack
- You can restart a single service without affecting the others
- You've done a full update cycle (pull + up) and verified everything came back healthy

### Task 5: Resource Awareness

Know what your stack costs in terms of server resources.

**Success criteria:**
- You've run `docker stats --no-stream` and can read the output
- You know approximately how much RAM your full stack uses
- You know which service uses the most resources
- You've considered whether your Lightsail instance size is right for the load

---

## Hints

<details>
<summary>Hint 1: Where's the system prompt?</summary>

After onboarding, OpenClaw stores its configuration in the `config/` directory that's bind-mounted into the container. Look for YAML or JSON files there. You can also shell into the container (`docker compose exec openclaw bash`) and explore `~/.openclaw/`.
</details>

<details>
<summary>Hint 2: How to verify SearXNG is being used</summary>

Watch both logs simultaneously. In one terminal, run `docker compose logs -f openclaw`. In another, run `docker compose logs -f searxng`. Send a question that requires current information. You should see a request appear in the SearXNG logs at the same time OpenClaw processes the message.

You can also test SearXNG directly:
```bash
curl "http://127.0.0.1:8080/search?q=test&format=json" | python3 -m json.tool | head -30
```
</details>

<details>
<summary>Hint 3: Changing models and the config flow</summary>

Model configuration is typically in the OpenClaw config files under `config/`. After changing the model, you need to restart OpenClaw for the change to take effect:

```bash
docker compose restart openclaw
```

You don't need to bring the whole stack down -- just restart the one service. Check the logs after restarting to confirm it loaded the new model configuration:

```bash
docker compose logs openclaw | tail -20
```

For resource awareness: on a 2 GB instance, your full stack should use roughly 500-800 MB RAM. OpenClaw and Uptime Kuma are typically the hungriest. If total usage exceeds ~1.5 GB, you might need a larger instance or should investigate which service is consuming more than expected.
</details>

---

## Solution

<details>
<summary>Click to expand the full walkthrough</summary>

### Task 1: System Prompt

Shell into the container to find config files:

```bash
docker compose exec openclaw bash
ls -la ~/.openclaw/
```

Look for a configuration file (likely YAML or JSON) that contains a `system_prompt` or `personality` field. Edit it on your host machine since the directory is bind-mounted:

```bash
# Back on the host
nano ~/openclaw-stack/config/settings.yml  # or whatever the config file is called
```

Example system prompt customization:

```
You are my personal AI assistant. I'm a product manager based in Istanbul.
Keep responses concise unless I ask for detail. When I ask you to search
for something, include the source URLs. If I send you a voice note
transcription that seems garbled, ask me to clarify rather than guessing.
```

After editing:

```bash
docker compose restart openclaw
```

Test by sending a message that should trigger the new behavior.

### Task 2: SearXNG Verification

Open two SSH sessions (or use tmux):

**Terminal 1:**
```bash
cd ~/openclaw-stack
docker compose logs -f searxng
```

**Terminal 2:**
```bash
cd ~/openclaw-stack
docker compose logs -f openclaw
```

From WhatsApp, send: "Search the web for the latest Docker Compose release notes"

In Terminal 1, you should see SearXNG receive a search request. In Terminal 2, you should see OpenClaw process the results.

Direct test:
```bash
curl -s "http://127.0.0.1:8080/search?q=docker+compose&format=json" | python3 -m json.tool | head -40
```

### Task 3: Model Exploration

Check available models in the OpenClaw config:

```bash
docker compose exec openclaw openclaw models
# or check the config file
cat ~/openclaw-stack/config/settings.yml
```

To switch models, edit the config to use a different Claude model (e.g., `claude-3-haiku-20240307` for faster/cheaper, or `claude-sonnet-4-20250514` for the latest), restart, and test:

```bash
docker compose restart openclaw
```

Send the same question with both models and compare response quality and speed. Haiku is roughly 10x cheaper but less capable for complex reasoning. For most personal assistant tasks, it's perfectly fine.

### Task 4: Operations Practice

Run through each command:

```bash
# Status check
docker compose ps

# Live logs
docker compose logs -f openclaw
# (Ctrl+C to stop)

# Single service restart
docker compose restart openclaw
docker compose ps  # verify it came back

# Full cycle
docker compose down
docker compose ps  # everything gone
docker compose up -d
docker compose ps  # everything back

# Update cycle
docker compose pull
docker compose up -d
docker compose ps  # verify healthy after update
```

### Task 5: Resource Check

```bash
docker stats --no-stream
```

Example output on a 2 GB instance:

```
CONTAINER    CPU %     MEM USAGE / LIMIT   MEM %
openclaw     0.50%     180MiB / 1.94GiB    9.06%
searxng      0.10%     85MiB / 1.94GiB     4.28%
uptime-kuma  0.30%     120MiB / 1.94GiB    6.04%
cloudflared  0.05%     25MiB / 1.94GiB     1.26%
killswitch   0.01%     5MiB / 1.94GiB      0.25%
```

Total: roughly 415 MiB. Plenty of headroom on a 2 GB instance. The numbers will spike during active conversations (OpenClaw processing) and during search queries.

If you're consistently above 1.5 GB total RAM usage, consider upgrading to the 4 GB Lightsail tier. Check `free -h` for a system-wide view that includes the OS overhead.

</details>

---

## What You've Learned

By completing this challenge, you've gone from "it works" to "it works the way I want it to." You can:

- Find and edit OpenClaw's configuration
- Verify that all services are communicating correctly
- Make informed decisions about AI model trade-offs
- Operate your stack confidently with daily commands
- Monitor resource usage and know what's normal

This is the difference between following a tutorial and owning your deployment.

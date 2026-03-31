# Challenge: Make It Yours

## The Scenario

Your bot works. It answers questions, it lives in a Docker container on your laptop, and you've probably already shown it to at least one friend. But right now it's... generic. It's just Claude-in-a-Telegram-wrapper. Let's give it some personality and push it a little.

## Your Mission

Customize your OpenClaw bot in three ways. Do as many as you like -- this is supposed to be fun, not homework.

---

### Challenge 1: Give It a Personality

**Task:** Change your bot's system prompt so it responds in a distinctive way.

OpenClaw uses a file called `SOUL.md` in its workspace directory to define the agent's personality. You can edit it to make your bot respond however you want.

Some ideas:
- A sarcastic British butler ("Very well, sir. I shall research that for you. Though I must say, one might have simply Googled it.")
- A pirate ("Arrr, ye want to know about Python decorators? Gather 'round, matey.")
- An overly enthusiastic motivational coach ("GREAT question! You're already CRUSHING IT by asking!")
- Your favorite fictional character

**Success criteria:** Send your bot a question and get a response that matches the personality you set.

<details>
<summary>Hint 1 -- Where's the config?</summary>

OpenClaw's config and personality files live at `/home/node/.openclaw/` inside the container. The main config is `openclaw.json` (JSON5 format), and the personality is defined in `workspace/SOUL.md`.

You can explore with the CLI service:

```bash
docker compose run --rm openclaw-cli bash
ls -la /home/node/.openclaw/
ls -la /home/node/.openclaw/workspace/
cat /home/node/.openclaw/workspace/SOUL.md
```

</details>

<details>
<summary>Hint 2 -- How to edit SOUL.md</summary>

You can edit SOUL.md directly inside the container:

```bash
docker compose run --rm openclaw-cli bash
# Then inside the container:
vi /home/node/.openclaw/workspace/SOUL.md
```

Or you can use the OpenClaw CLI:

```bash
docker compose run --rm openclaw-cli openclaw config set personality "Your personality description here"
```

Write something like:

```markdown
You are a sarcastic but helpful AI assistant who speaks like a Victorian-era
British butler. You always address the user as "sir" or "madam" and occasionally
express mild exasperation at the simplicity of their questions, while still
providing excellent answers.
```

</details>

<details>
<summary>Hint 3 -- After changing</summary>

After editing SOUL.md, restart the gateway:

```bash
docker compose restart openclaw-gateway
```

Then send a new message in Telegram to test.

</details>

---

### Challenge 2: Try a Different Model

**Task:** Switch between Claude models (or to GPT) and notice the difference.

Different models have different strengths. Claude Sonnet is fast and cheap. Claude Opus is smarter but slower and more expensive. GPT-4o is great at certain tasks. Try switching and see what you notice.

**Success criteria:** Have the same conversation with two different models and notice a difference in response quality, speed, or style.

<details>
<summary>Hint 1 -- Where to change models</summary>

You can list available models and switch:

```bash
docker compose run --rm openclaw-cli openclaw models list
docker compose run --rm openclaw-cli openclaw config set model "claude-opus-4-20250514"
docker compose restart openclaw-gateway
```

Common model names:

- `claude-sonnet-4-20250514` (fast, cheap, good for most things)
- `claude-opus-4-20250514` (smartest, slower, more expensive)
- `gpt-4o` (if you have an OpenAI key)

</details>

<details>
<summary>Hint 2 -- A good test</summary>

Ask both models the same complex question to compare. Try something like:
- "Explain the CAP theorem using a pizza delivery analogy"
- "Write a Python function that finds the longest palindromic substring"
- "What are the pros and cons of microservices vs monoliths?"

</details>

---

### Challenge 3: Stress Test It

**Task:** Find the limits. What happens when you push it?

Your bot is running in Docker on your laptop. It shares resources with everything else you're running. Let's see what happens when you push it.

Try these (one at a time):
- Send a very long message (1000+ words)
- Ask it to generate a very long response ("Write a 2000-word essay about...")
- Send multiple messages rapidly without waiting for responses
- Ask it to browse a website (OpenClaw has a built-in Chromium browser!)
- Ask it about events after its training cutoff

**Success criteria:** Understand where the limits are. What works? What breaks? What's slow?

> **Important:** Don't worry about breaking anything. The worst that happens is OpenClaw gets confused or the container needs a restart. `docker compose restart openclaw-gateway` fixes most things.

---

### Bonus Challenge: Close the Lid Test

**Task:** Close your laptop lid, wait 30 seconds, then open it and send a message.

What happens? Does the bot respond immediately? Does it take a minute? Does it fail entirely?

This is the exact problem the full course solves. Your bot only lives as long as your laptop is awake. In Module 4, we put it on a server that never sleeps. In Module 6, we verify it works 24/7 even when your laptop is off.

---

## Reflection

After completing the challenges, think about:

- **What would you change** if this was your daily driver? What features are missing?
- **What worries you** about the current setup? (Hint: it stops when you close your laptop.)
- **What would it take** to let someone else use this? A friend? A team?

These are exactly the questions the full course answers. When you're ready to do this properly -- on a server that runs 24/7, with encrypted secrets, a firewall, monitoring, and a kill switch -- start with [Module 1: What Are AI Agents?](../01-ai-agents/episode.md).

---

## Cleaning Up (If You're Done)

If you decide not to continue with the full course and want to free up resources:

```bash
# Stop the containers
cd ~/openclaw-local
docker compose down

# Remove the data volume too (deletes all OpenClaw data)
docker compose down -v

# Remove the downloaded image (optional, frees disk space)
docker rmi ghcr.io/openclaw/openclaw:latest
```

If you're continuing to the full course, **keep Docker Desktop installed and the project folder** -- we'll use them in the next modules.

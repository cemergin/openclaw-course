# Challenge 3: Explore OpenClaw's Superpowers

## The Scenario

Your bot is alive and you have a config-as-code repo. But you've barely scratched the surface. OpenClaw has skills, memory, a built-in browser, 35+ tools, and support for 20+ AI models. Time to explore.

These challenges are independent -- do them in any order, skip the ones that don't interest you. But try at least three. This is the module where you discover what your bot can actually do.

---

### Challenge 1: Install a Skill from ClawHub

**Task:** Browse the ClawHub marketplace and install a community skill.

**1. See what's available:**

```bash
docker compose run --rm openclaw-cli openclaw skills search
```

Or browse with a keyword:

```bash
docker compose run --rm openclaw-cli openclaw skills search summarizer
```

**2. Install a skill that looks interesting:**

```bash
docker compose run --rm openclaw-cli openclaw skills install clawhub/summarizer
```

**3. Restart the gateway and test it:**

```bash
cd ~/openclaw
docker compose restart openclaw-gateway
```

Then message your bot on Telegram with something that triggers the skill. If you installed a summarizer, send it a long article URL and ask for a summary.

**4. Inspect the skill:**

```bash
docker compose run --rm openclaw-cli bash
ls -la /home/node/.openclaw/workspace/skills/
cat /home/node/.openclaw/workspace/skills/summarizer/SKILL.md
exit
```

Skills are just Markdown files. You can read them, edit them, or write your own from scratch.

**Success criteria:** A skill from ClawHub is installed and your bot uses it when appropriate.

---

### Challenge 2: Switch Models

**Task:** Change your AI model and notice the difference.

**1. See available models:**

```bash
docker compose run --rm openclaw-cli openclaw models list
```

**2. Switch to a different model:**

Edit your `~/my-openclaw/config/openclaw.json` and change the model line:

```json5
model: {
  provider: "anthropic",
  model: "claude-opus-4-20250514",  // Was claude-sonnet-4
  apiKey: { source: "env", id: "ANTHROPIC_API_KEY" },
},
```

Or if you have an OpenAI key, try:

```json5
model: {
  provider: "openai",
  model: "gpt-4o",
  apiKey: { source: "env", id: "OPENAI_API_KEY" },
},
```

**3. Copy in the new config and restart:**

```bash
docker cp ~/my-openclaw/config/openclaw.json openclaw-gateway:/home/node/.openclaw/openclaw.json
cd ~/openclaw
docker compose restart openclaw-gateway
```

**4. Compare:** Ask both models the same question. Try:
- "Explain the CAP theorem using a pizza delivery analogy"
- "Write a Python function to detect palindromes"
- "What's the most underrated programming language and why?"

**5. Commit your choice:**

When you decide which model you prefer, commit the config change:

```bash
cd ~/my-openclaw
git add config/openclaw.json
git commit -m "Switch to [model name] -- better for [your reason]"
```

**Success criteria:** You've tried at least two different models and committed your preferred choice to the repo.

---

### Challenge 3: Explore Memory

**Task:** Have a conversation with your bot, then inspect its memory files.

**1. Tell your bot some facts about yourself.** Over several messages:

- "My name is [your name] and I'm a [your profession]"
- "I'm working on a project called [project name]"
- "I prefer Python over JavaScript"
- "I live in [city]"

**2. Have a longer conversation.** Ask it to help with something real -- a code problem, a writing task, whatever.

**3. Now inspect the memory files:**

```bash
docker compose run --rm openclaw-cli bash
cat /home/node/.openclaw/workspace/MEMORY.md
ls -la /home/node/.openclaw/workspace/memory/
cat /home/node/.openclaw/workspace/memory/$(date +%Y-%m-%d).md
exit
```

**4. Check what it remembers.** Start a new conversation (or wait a bit) and ask:

- "What's my name?"
- "What project am I working on?"
- "What programming language do I prefer?"

If the memory system is working, your bot should know these things even in a new conversation.

**5. Look at the SQLite database:**

```bash
docker compose run --rm openclaw-cli bash
ls -la /home/node/.openclaw/*.db
exit
```

OpenClaw uses SQLite for conversation history search. The MEMORY.md file is for curated long-term facts; the database stores everything.

**Success criteria:** You can see your bot's memory files and it remembers facts across conversations.

---

### Challenge 4: Try the Built-In Browser

**Task:** Ask your bot to browse a website. Yes, it has a real browser.

OpenClaw includes a headless Chromium instance. Your bot can actually visit websites, read their content, fill in forms, and take screenshots.

**1. Ask your bot to browse:**

Try these in Telegram:
- "Go to news.ycombinator.com and tell me what the top 3 stories are"
- "Visit wikipedia.org and find a random interesting fact"
- "Check the current weather at weather.com for [your city]"

**2. Watch the logs while it browses:**

```bash
docker compose logs -f openclaw-gateway
```

You'll see the browser launch, navigate to the URL, and extract content. It's surprisingly fast.

**3. Try something interactive:**

- "Search Google for 'best Docker practices 2026' and summarize the top results"
- "Go to [a URL you choose] and summarize the page"

> **Note:** The browser runs inside the Docker container. It can't access things that require login (unless you configure those credentials). And it respects robots.txt. Don't ask it to scrape anything shady.

**Success criteria:** Your bot successfully browses at least one website and reports back useful information.

---

### Challenge 5: Personality Lab

**Task:** Try three different SOUL.md personalities and see how they change behavior.

**1. Save your current personality:**

```bash
cp ~/my-openclaw/workspace/SOUL.md ~/my-openclaw/workspace/SOUL.md.backup
```

**2. Try Personality A: The Minimalist**

Write a new SOUL.md:

```markdown
# Soul

You answer in 1-3 sentences maximum. No fluff. No pleasantries.
If you can answer in one word, do it.
```

Copy it in, restart, test.

**3. Try Personality B: The Storyteller**

```markdown
# Soul

You explain everything through stories and analogies. Every answer begins
with "Once upon a time..." or "Imagine this..." You turn every technical
concept into a narrative. You're the Pixar of AI assistants -- you make
complex things simple through compelling stories.
```

Copy it in, restart, test.

**4. Try Personality C: The Pair Programmer**

```markdown
# Soul

You are a senior software engineer doing pair programming. You think out
loud. You consider tradeoffs. You ask clarifying questions before jumping
to code. When you write code, you explain WHY, not just WHAT.

You push back gently when you see bad practices. You suggest tests.
You care about maintainability over cleverness.
```

Copy it in, restart, test.

**5. Pick your favorite and commit it:**

```bash
# Restore your favorite (or keep the latest)
cd ~/my-openclaw
git add workspace/SOUL.md
git commit -m "Settle on [personality style] for SOUL.md"
```

**Success criteria:** You've tested at least 3 different personalities and committed your favorite.

---

### Challenge 6: The CLI Power Tour

**Task:** Explore OpenClaw's CLI commands and discover what else it can do.

```bash
# See all available commands
docker compose run --rm openclaw-cli openclaw --help

# Check system health
docker compose run --rm openclaw-cli openclaw doctor

# View current config
docker compose run --rm openclaw-cli openclaw config get

# List configured channels
docker compose run --rm openclaw-cli openclaw channels list

# Check gateway status
docker compose run --rm openclaw-cli openclaw gateway status

# List installed skills
docker compose run --rm openclaw-cli openclaw skills list

# List available models for your provider
docker compose run --rm openclaw-cli openclaw models list
```

**Bonus:** Can you find a command that lets you set config values from the CLI? Try:

```bash
docker compose run --rm openclaw-cli openclaw config set model.model "claude-haiku-3-20250307"
```

**Success criteria:** You've run at least 5 different CLI commands and understand what they do.

---

### Bonus Challenge: Add a Second Channel

**Task:** Add Discord (or another channel) alongside Telegram.

If you have a Discord server, try adding a Discord bot:

1. Go to [discord.com/developers](https://discord.com/developers/applications)
2. Create a new application
3. Go to Bot settings and create a bot
4. Copy the bot token
5. Add it to OpenClaw:

```bash
docker compose run --rm openclaw-cli openclaw channels add discord
```

6. Restart the gateway
7. Invite the bot to your Discord server
8. Message it on both Telegram and Discord

Same bot, two channels, one brain.

**Success criteria:** Your bot responds on both Telegram and a second channel.

---

## Reflection

After exploring these challenges, think about:

- **Which tools surprised you?** The browser? The skills system? Memory?
- **How would you use this daily?** What personality and skills would your ideal bot have?
- **What makes you nervous?** Shell access? Browser access? Memory that persists?
- **What's missing?** What would you need before trusting this as your daily driver?

The answers to that last question are exactly what the rest of the course covers:
- **Module 4:** A server that runs 24/7
- **Module 5:** Git push to deploy
- **Module 7:** Security and secrets management
- **Module 8:** Cloudflare Tunnel (zero open ports)
- **Module 9:** Monitoring and kill switch

Your config-as-code repo is the foundation. Everything else builds on top.

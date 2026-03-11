# Challenge: Make It Yours

## The Scenario

Your bot works. It answers questions, it's running 24/7, and you've probably already shown it to at least one friend. But right now it's... generic. It's just Claude-in-a-Telegram-wrapper. Let's give it some personality and push it a little.

## Your Mission

Customize your OpenClaw bot in three ways. Do as many as you like -- this is supposed to be fun, not homework.

---

### Challenge 1: Give It a Personality

**Task:** Change your bot's system prompt so it responds in a distinctive way.

OpenClaw lets you customize how the AI behaves through its configuration. Find the config and change the system prompt to something that makes you smile.

Some ideas:
- A sarcastic British butler ("Very well, sir. I shall research that for you. Though I must say, one might have simply Googled it.")
- A pirate ("Arrr, ye want to know about Python decorators? Gather 'round, matey.")
- An overly enthusiastic motivational coach ("GREAT question! You're already CRUSHING IT by asking!")
- Your favorite fictional character

**Success criteria:** Send your bot a question and get a response that matches the personality you set.

<details>
<summary>Hint 1 -- Where's the config?</summary>

Check `~/.openclaw/` on your server. Look for a config file (`.yaml`, `.json`, or `.toml`). There should be a field for the system prompt or agent personality.

</details>

<details>
<summary>Hint 2 -- What to change</summary>

Look for a field called something like `system_prompt`, `personality`, or `instructions`. Replace its value with your custom prompt. For example:

```
You are a sarcastic but helpful AI assistant who speaks like a Victorian-era British butler. You always address the user as "sir" or "madam" and occasionally express mild exasperation at the simplicity of their questions, while still providing excellent answers.
```

</details>

<details>
<summary>Hint 3 -- After changing</summary>

After editing the config, restart OpenClaw:

```bash
openclaw stop
nohup openclaw start > ~/openclaw.log 2>&1 &
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

Check your OpenClaw config or run `openclaw onboard` again to change the model. Common model names:

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

Your bot is running on a server with 1 GB of RAM and 1 CPU. That's not a lot. Let's see what happens when you push it.

Try these (one at a time):
- Send a very long message (1000+ words)
- Ask it to generate a very long response ("Write a 2000-word essay about...")
- Send multiple messages rapidly without waiting for responses
- Ask it to do something impossible ("Browse to google.com and tell me the top result")
- Ask it about events after its training cutoff

**Success criteria:** Understand where the limits are. What works? What breaks? What's slow?

> **Important:** Don't worry about breaking anything. The worst that happens is OpenClaw crashes and you restart it. Your server is fine.

---

## Reflection

After completing the challenges, think about:

- **What would you change** if this was your daily driver? What features are missing?
- **What worries you** about the current setup? (Hint: security. Lots of security.)
- **What would it take** to let someone else use this? A friend? A team?

These are exactly the questions the full course answers. When you're ready to do this properly -- with WhatsApp, encrypted secrets, a firewall, monitoring, and a kill switch -- start with [Module 1: What Are AI Agents?](../01-ai-agents/episode.md).

---

## Cleaning Up (If You're Done)

If you decide not to continue with the full course and want to avoid any charges:

1. Go to [lightsail.aws.amazon.com](https://lightsail.aws.amazon.com/)
2. Click on your instance
3. Click **Delete** (under the three-dot menu)
4. Confirm deletion

This stops all charges immediately. Your server and everything on it will be gone forever.

If you're continuing to the full course, **keep the instance running** -- we'll use it in the next modules (and rebuild it properly).

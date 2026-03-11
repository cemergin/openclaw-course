# Challenge: Explore the API Playground

## The Scenario

You've got your API keys. But before we install anything on a server, let's actually *use* the AI APIs directly. Anthropic and OpenAI both have browser-based playgrounds where you can send messages to their models and see the responses -- no code required.

Your mission: send the same prompt to different models, compare the results, and get an intuitive feel for how these APIs work, what the different models are good at, and how much things cost.

This matters because when your OpenClaw agent is running, it's making exactly these API calls behind the scenes. Understanding the playground now means you'll be able to debug and optimize later.

---

## Your Task

### Part 1: Talk to Claude via the Workbench

1. Go to [console.anthropic.com](https://console.anthropic.com/) and open the **Workbench** (in the left sidebar)
2. You'll see a chat-like interface where you can send messages to Claude models
3. Select **Claude Sonnet** as the model (this will be your default for OpenClaw)
4. Send this exact prompt:

   > You are a helpful personal AI agent. The user just sent you this message via WhatsApp: "Hey, what's a good recipe for dinner tonight? I have chicken, rice, and broccoli." Respond naturally, like a friendly assistant.

5. Note the response. Check the token count and estimated cost shown in the interface.

6. Now switch to **Claude Haiku** and send the same prompt. Compare:
   - How does the response quality differ?
   - How does the cost differ?
   - How does the speed feel?

7. If you have access, try **Claude Opus** with the same prompt. Notice the quality jump -- and the price jump.

### Part 2: Talk to GPT via the Playground (Optional)

8. Go to [platform.openai.com/playground](https://platform.openai.com/playground)
9. Select **GPT-4o** and send the same prompt from step 4
10. Compare the GPT-4o response to Claude Sonnet's response:
    - Which feels more natural for a personal assistant?
    - Which one followed the "via WhatsApp" context better?
    - Any differences in tone, length, or helpfulness?

### Part 3: Stress-Test with a Harder Prompt

11. Go back to the Claude Workbench and send something more complex:

    > I need to write a professional but warm email declining a meeting invitation from my manager. The meeting is about Q3 planning, scheduled for Thursday at 2pm. I have a conflict with a client call that I can't move. Suggest I'm happy to review the notes afterward and contribute async.

12. Read the response. This is closer to what your agent will actually do day-to-day.

13. Now try a prompt that involves reasoning:

    > I'm deciding between AWS Lightsail ($5/mo, 1GB RAM, managed) and Hetzner CAX11 ($4/mo, 4GB RAM, unmanaged). I want to run an AI agent with Docker. I'm new to servers. What would you recommend and why?

14. Notice how the model handles tradeoffs and recommendations. This is the kind of thinking your agent does when you ask it for help.

---

## Success Criteria

- [ ] You sent at least one message via the Claude Workbench
- [ ] You compared responses from at least two different Claude models
- [ ] You checked the token count/cost for at least one request
- [ ] You have a gut feel for the quality-vs-cost tradeoff between models
- [ ] (Bonus) You compared a Claude response to a GPT response for the same prompt

---

## Hints

<details>
<summary>Hint 1: Can't find the Workbench?</summary>

In the Anthropic Console (console.anthropic.com), look in the left sidebar. "Workbench" should be one of the top options. If you're on a mobile device, you might need to click a hamburger menu icon to expand the sidebar. The Workbench is essentially a chat playground for testing API calls without writing code.
</details>

<details>
<summary>Hint 2: Where are the token counts?</summary>

After you send a message in the Workbench, look below the response or in the right sidebar. You should see "input tokens" and "output tokens" counts. The pricing is per-token (roughly per word -- 1 token is approximately 0.75 words in English). Multiply the token counts by the per-token price on the pricing page to estimate cost.
</details>

<details>
<summary>Hint 3: The responses seem the same across models?</summary>

For simple prompts, the differences between models can be subtle. Try something harder -- ask for a nuanced analysis of a tradeoff, a creative writing piece, or a multi-step plan. The gap between Haiku and Opus becomes obvious on complex tasks. Haiku is great for quick answers; Opus shines when you need depth.
</details>

---

## Solution

<details>
<summary>What you should have observed (click to expand)</summary>

### Model Comparison (Typical Observations)

**Claude Haiku:**
- Responds almost instantly
- Gives a solid, concise answer
- Might miss subtle context clues (like adjusting tone for WhatsApp vs email)
- Cheapest option by far
- Best for: simple Q&A, quick lookups, high-volume low-stakes tasks

**Claude Sonnet:**
- Responds in 1-3 seconds
- Balanced quality -- good at following nuanced instructions
- Picks up on context like "via WhatsApp" and adjusts format/length appropriately
- Mid-range pricing
- Best for: daily personal agent use (this is what we'll default to)

**Claude Opus:**
- May take a few seconds longer
- Noticeably better on complex reasoning, nuanced writing, multi-step plans
- Most expensive (roughly 5x Sonnet for the same prompt)
- Best for: complex analysis, important emails, situations where quality matters most

**GPT-4o (if tested):**
- Comparable quality to Claude Sonnet for most tasks
- May format responses differently (more bullet points, different conversational style)
- Neither is strictly "better" -- they have different personalities
- The choice often comes down to personal preference and which handles your specific use cases better

### Cost Observations

A simple recipe request probably used:
- ~100-200 input tokens ($0.0003 - $0.0006 on Sonnet)
- ~200-400 output tokens ($0.001 - $0.002 on Sonnet)
- **Total: well under a penny per message**

This is why personal AI agent use is so cheap. Even at 50-100 messages per day, you're looking at $0.50-2.00 per day.

### The Takeaway

For OpenClaw, we'll default to **Claude Sonnet** -- it's the sweet spot of quality, speed, and cost for a personal agent. But knowing the full spectrum means you can make smart choices later: use Haiku for simple tasks to save money, escalate to Opus for complex reasoning when it matters.
</details>

---

## Reflection

After this challenge, you should have a visceral understanding of what's happening when your AI agent processes a message. It's not magic -- it's an API call. Your message goes in as tokens, the model thinks, and a response comes back. OpenClaw is the software that automates this loop: receive message from chat app, format it into an API call, send the response back.

Every message your agent handles in the future is exactly what you just did in the playground -- but automated, with memory, and available 24/7 from your phone.

Pretty cool, right? Now let's go build the infrastructure to make it happen.

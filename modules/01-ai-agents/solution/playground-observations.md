# API Playground Observations -- Example Solution

These are representative observations. Your specific results will vary based on
model versions, prompt phrasing, and random sampling.

## Model Comparison: Simple Agent Task (Prompt 1)

### Claude Haiku
- Quality: 3/5 -- Gave a workable recipe, but response was generic.
  Didn't fully pick up on the "via WhatsApp" context (response was
  a bit long for a chat message).
- Speed: Near instant (~0.5s)
- Token count: ~85 in / ~180 out
- Cost estimate: ~$0.0003
- Verdict: Fast and cheap. Fine for simple tasks.

### Claude Sonnet
- Quality: 4/5 -- Good recipe with a friendly, conversational tone.
  Kept the response WhatsApp-appropriate (concise, used line breaks well).
  Added a nice personal touch.
- Speed: ~1-2 seconds
- Token count: ~85 in / ~220 out
- Cost estimate: ~$0.002
- Verdict: The sweet spot. This is what we'll use daily.

### Claude Opus
- Quality: 5/5 -- Excellent response. Picked up nuance, gave a great
  recipe with optional variations, perfect WhatsApp-length response.
  Felt genuinely helpful and warm.
- Speed: ~3-5 seconds
- Token count: ~85 in / ~280 out
- Cost estimate: ~$0.01
- Verdict: Noticeably better, but 5x the cost. Save for complex tasks.

### GPT-4o (Optional)
- Quality: 4/5 -- Different style from Claude. More structured
  (used bullet points). Equally helpful but felt slightly more
  "assistant-like" vs Claude's more "friend-like" tone.
- Speed: ~1-2 seconds
- Token count: ~85 in / ~250 out
- Cost estimate: ~$0.002
- Verdict: Comparable to Claude Sonnet. Preference is subjective.

## Key Takeaways

1. **Sonnet is the right default for a personal agent.** The quality-to-cost
   ratio is excellent. Haiku is too terse for conversational use; Opus is
   overkill for most daily tasks.

2. **Cost is trivial for personal use.** Even at $0.002 per message and
   100 messages/day, that's $0.20/day or about $6/month.

3. **Model choice matters less than you'd think for simple tasks.**
   The differences really show up on complex reasoning, creative writing,
   and nuanced instructions. For "what should I make for dinner?", even
   Haiku does a decent job.

4. **Claude and GPT have different "personalities."** Neither is strictly
   better. Claude tends to be more conversational and warm; GPT tends to
   be more structured and thorough. Try both and see which feels right
   for your personal assistant.

## Recommended OpenClaw Configuration

- **Default model:** Claude Sonnet (good for 90% of tasks)
- **Budget model:** Claude Haiku (for simple lookups, high-volume tasks)
- **Premium model:** Claude Opus (for complex reasoning, important emails)
- **Monthly budget:** $10-15 for moderate personal use

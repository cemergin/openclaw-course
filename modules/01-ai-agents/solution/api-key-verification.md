# Solution: API Key Verification

## How to Verify Your Keys Work

After completing the exercise, you should have API keys saved in your password manager. Here's how to verify they're working before we use them in later modules.

### Quick Test: Claude API Key

You can test your Claude key from any terminal using `curl`:

```bash
curl https://api.anthropic.com/v1/messages \
  -H "content-type: application/json" \
  -H "x-api-key: YOUR_KEY_HERE" \
  -H "anthropic-version: 2023-06-01" \
  -d '{
    "model": "claude-sonnet-4-20250514",
    "max_tokens": 100,
    "messages": [{"role": "user", "content": "Say hello in exactly 5 words."}]
  }'
```

**Expected:** A JSON response with Claude's reply.
**If it fails:** Check that your key is correct and billing is active.

> **Important:** Replace `YOUR_KEY_HERE` with your actual key. And don't run this in a shared terminal or save it in a shell history file on a shared machine.

### Quick Test: OpenAI API Key (Optional)

```bash
curl https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_KEY_HERE" \
  -d '{
    "model": "gpt-4o",
    "messages": [{"role": "user", "content": "Say hello in exactly 5 words."}],
    "max_tokens": 100
  }'
```

**Expected:** A JSON response with GPT's reply.

### What You Should Have After This Module

1. At least one working API key (Claude recommended)
2. Spending limits configured on all accounts
3. Keys stored in a password manager
4. A mental model of how AI agents differ from chatbots and assistants
5. Understanding of the OpenClaw architecture (you -> chat app -> Docker -> AI API)

### What's Next

In **Module 2**, we dive into Docker properly -- images, containers, Compose, volumes, networks. You'll use your API key for the first time when we set up OpenClaw in **Module 3**.

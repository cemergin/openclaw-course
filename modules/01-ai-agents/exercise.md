# Exercise: Get Your API Keys Ready

## What We're Doing

We're going to sign up for AI API accounts, generate API keys, set spending limits, and make sure billing is active. By the end, you'll have at least one working API key saved somewhere safe -- the "brain" for your future AI agent.

## Prerequisites

- A web browser
- A credit or debit card (for API billing -- you won't be charged much; typical personal use is $5-15/month)
- A password manager or secure note-taking app to store your keys

---

## Part 1: Get Your Claude API Key (Recommended)

### Step 1: Create your Anthropic account

Go to [console.anthropic.com](https://console.anthropic.com/) and sign up for an account.

You'll see the Anthropic Console dashboard. It's clean and minimal -- a sidebar on the left with options like Workbench, API Keys, and Settings.

> **Pro tip:** This is the *API console*, not claude.ai (the chat app). They're separate products with separate accounts, though you can use the same email. The console is where developers manage API access.

### Step 2: Add billing information

Before your API key will actually work, you need a payment method on file.

1. Click **Settings** in the left sidebar (or the gear icon)
2. Click **Plans & Billing**
3. Click **Add Payment Method** and enter your card details
4. You're on the pay-as-you-go plan by default -- that's what we want

You'll see a billing dashboard showing your current usage (which should be $0.00 right now). This is where you'll check costs later.

### Step 3: Set a spending limit

This is not optional. Do this now.

1. Still in **Plans & Billing**, look for **Usage Limits**
2. Set a **monthly spending limit** -- $10 is a good starting point for learning (you can always raise it later)
3. You can also set a **notification threshold** at a lower amount (like $5) so you get an email heads-up before hitting the limit

**Before moving on, predict this:** What do you think happens when you hit your spending limit? Does the API return an error, slow down, or keep working and charge you extra?

*Answer: It returns an error. Your requests will be rejected with a rate limit error until the next billing cycle or until you raise the limit. No surprise bills.*

### Step 4: Generate your API key

1. Click **API Keys** in the left sidebar
2. Click **Create Key**
3. Give it a name that helps you remember what it's for -- something like `openclaw-dev` or `my-agent-key`
4. Click **Create Key**
5. You'll see your key displayed: it starts with `sk-ant-api03-` followed by a long string of characters

**CRITICAL:** Copy this key right now and save it in your password manager. You will **never** see this key again after you close this dialog. If you lose it, you'll have to create a new one.

The key looks something like this (this is fake, obviously):
```
sk-ant-api03-abcDEF123456789xyzABCDEF123456789xyzABCDEF123456789xyzABCDEF1234-abcDEF123456789xyzABCDEF123456789xyzABCDEF12345678
```

### Step 5: Verify your key is saved

Open your password manager or secure note and confirm the key is there. Read the first few characters (`sk-ant-`) and the last few characters to make sure nothing got truncated during copy-paste.

> **Pro tip:** Some password managers have a "Secure Notes" feature -- that's perfect for API keys. Create one called "AI API Keys" and store all your keys there.

---

## Part 2: Get Your OpenAI API Key (Optional but Recommended)

Having both gives you the ability to compare models and switch between them. OpenClaw supports both.

### Step 6: Create your OpenAI platform account

Go to [platform.openai.com](https://platform.openai.com/) and sign up.

Again, this is the *API platform*, separate from chatgpt.com. You'll see a dashboard with options for API Keys, Usage, Billing, and a Playground.

### Step 7: Add billing and set limits

1. Click **Settings** in the left sidebar, then **Billing**
2. Click **Add payment method** and enter your card
3. You may need to add credit to your account (OpenAI uses a prepaid model -- you load credits, then spend them)
4. Start with $10 in credits -- that's plenty for experimentation
5. Set a **monthly budget limit** under the billing settings

### Step 8: Generate your OpenAI API key

1. Go to **API Keys** in the sidebar (or navigate to platform.openai.com/api-keys)
2. Click **Create new secret key**
3. Give it a name like `openclaw-dev`
4. Copy the key immediately -- same drill, you won't see it again
5. Save it in your password manager alongside your Claude key

The key looks like:
```
sk-proj-abcDEF123456789xyzABCDEF123456789xyzABCDEF12345678
```

---

## Part 3: Explore the Billing Dashboard

### Step 9: Understand how you'll be charged

Go back to your Anthropic Console and click through to the usage/billing section. Take a moment to familiarize yourself with:

- **Current period usage** -- your running total for the month
- **Usage by model** -- which models are costing you what
- **Rate limits** -- how many requests per minute you can make at your billing tier

Here are some rough costs to calibrate your expectations (as of early 2026):

| Action | Approximate Cost |
|--------|-----------------|
| A typical back-and-forth message (short) | $0.001 - $0.01 |
| Summarizing a long email | $0.01 - $0.05 |
| Analyzing a document (several pages) | $0.05 - $0.20 |
| Heavy daily personal use | $0.30 - $1.00/day |

These are ballpark figures. The actual cost depends on the model (Sonnet is cheaper than Opus), the length of your messages, and how much context the agent carries. The point is: it's cheap. A dollar a day of heavy use is very achievable.

### Step 10: Find where to revoke keys

This is a security habit worth building now. In both consoles, find the option to **delete** or **revoke** an API key. Don't actually do it -- just know where it is.

If you ever suspect a key has been compromised (accidentally pushed to GitHub, shared in a screenshot, etc.), you want to be able to revoke it in under 30 seconds. Bookmark both pages.

---

## What Just Happened?

You now have:

- [x] An Anthropic account with billing enabled and a spending limit set
- [x] A Claude API key saved securely in your password manager
- [x] (Optional) An OpenAI account with the same setup
- [x] (Optional) An OpenAI API key saved securely
- [x] An understanding of how API billing works and what things cost
- [x] Knowledge of where to revoke keys in an emergency

These keys are the "brain connection" for your AI agent. In the upcoming modules, we'll store them properly on your server using Docker secrets (not just pasting them into config files -- that's how keys get leaked).

---

## Try This (Optional Experiments)

1. **Check your rate limits.** In the Anthropic Console, look at your current tier's rate limits. How many requests per minute can you make? What happens if you exceed it?

2. **Create a second key.** Make another API key called `openclaw-test`. Notice how you now have two active keys. This is useful later -- you might use one for development and one for production. (You can delete the test key after.)

3. **Read the pricing page.** Go to [anthropic.com/pricing](https://anthropic.com/pricing) and look at the per-token costs for different Claude models. Notice the difference between Haiku (cheap, fast, less capable) and Opus (expensive, slower, most capable). Sonnet sits in the sweet spot for most agent use cases.

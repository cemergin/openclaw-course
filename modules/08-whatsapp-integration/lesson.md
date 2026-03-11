# WhatsApp -- The Real Integration

## Why Can't This Be As Easy As Telegram?

Remember Module 0? You talked to @BotFather, got a token, plugged it in, done. Thirty seconds, tops. If you've been dreading this module because you assumed WhatsApp would be the same... I have some news.

WhatsApp integration involves a Meta developer account, a Business app, a temporary access token, a permanent access token (different thing), a Phone Number ID (not your actual phone number), a Business Account ID, a webhook callback URL, a webhook verify token, webhook signature verification, and a subscription to the "messages" field. Oh, and Meta's developer portal has a UI that changes every few months, so any screenshots I include might already be wrong by the time you read this.

So why bother?

Because WhatsApp is where your actual conversations happen. Telegram is great for tech people, but if you want an AI agent you'll actually use every day -- one you can message as naturally as you'd text a friend -- WhatsApp is it. Three billion people use it. You're probably one of them. And once this is set up, it just works. The hard part is the setup, not the maintenance.

Let's understand what we're building before we start clicking around Meta's portal.

## The Full Message Flow

Here's what happens when you send a WhatsApp message to your bot. Every. Single. Step.

```
You type "Hey, what's the weather in Istanbul?"
  |
  v
WhatsApp app on your phone
  |
  v
Meta's WhatsApp servers (they receive every WhatsApp message)
  |
  v
Meta sees: "This message is for a Business API number"
  |
  v
Meta POSTs the message to your webhook URL:
  https://openclaw.yourdomain.com/webhook/whatsapp
  (with an HMAC-SHA256 signature in the headers)
  |
  v
Cloudflare receives the POST at their edge network
  |
  v
Cloudflare routes it through your tunnel to localhost:3000
  (outbound connection from YOUR server -- no open ports)
  |
  v
OpenClaw receives the webhook, verifies the signature,
  extracts the message text
  |
  v
OpenClaw sends the message to Claude API
  |
  v
Claude responds with "I don't have real-time weather data,
  but here's what I can tell you about Istanbul's climate..."
  |
  v
OpenClaw calls the WhatsApp Business API to send the reply:
  POST https://graph.facebook.com/v21.0/{PHONE_NUMBER_ID}/messages
  (using your permanent access token)
  |
  v
Meta delivers the reply to your WhatsApp chat
  |
  v
You see the response on your phone. Feels like magic.
```

That's ten hops. And yet it all happens in a few seconds. Let's break down the parts that are new.

## Webhooks: "Don't Call Us, We'll Call You"

If you haven't worked with webhooks before, here's the simplest explanation: a webhook is a URL on your server that another service calls when something interesting happens.

Think of it like a doorbell. Instead of you constantly checking "did anyone send me a message? how about now? now? now?" (that's called *polling*), you give Meta your address and say "ring this doorbell whenever a message arrives." Meta rings it. You answer.

In technical terms:

1. You tell Meta: "My webhook URL is `https://openclaw.yourdomain.com/webhook/whatsapp`"
2. Someone sends you a WhatsApp message
3. Meta makes an HTTP POST request to that URL with the message data
4. Your server processes it and responds

The beauty of our Cloudflare Tunnel setup is that this URL works even though your server has zero open inbound ports. Meta hits the Cloudflare edge, Cloudflare sends it down the tunnel, and it arrives at OpenClaw as if it were a local request. The webhook has no idea it's going through a tunnel. It just works.

### The Verification Handshake

Before Meta will start sending you webhooks, it needs to verify that you actually own the URL. This happens once, during setup:

1. You enter your callback URL and a **verify token** (a random string you choose)
2. Meta sends a GET request to your URL with the verify token
3. Your server checks: "Is this the token I'm expecting?" If yes, it responds with a challenge code
4. Meta says "Great, this URL is legit" and starts sending webhooks

This is like Meta knocking on your door and asking "What's the secret password?" You answer correctly, and from then on, they know that door belongs to you.

> **Pro tip:** The verify token is NOT the same as your access token. The verify token is a random string you make up -- it's used once during setup to prove you own the URL. The access token is what you use to *send* messages through the WhatsApp API. Different things, confusing names. Classic Meta.

## HMAC-SHA256: Proving Meta Sent the Message

Okay, so Meta is sending webhooks to your URL. But here's a question: how do you know it's actually Meta, and not some random person who discovered your webhook URL and is sending fake messages?

This is where **HMAC-SHA256 signature verification** comes in. Don't let the name scare you -- the concept is beautifully simple.

### The Concept (No Math Required)

Imagine you and a friend have a shared secret word: "pineapple." When your friend sends you a letter, they take the letter's text, combine it with "pineapple," and run it through a blender (a hash function). The result is a unique fingerprint -- a signature.

They write this signature on the envelope.

When you receive the letter, you take the letter's text, combine it with "pineapple" (you both know it), and run it through the same blender. If your signature matches the one on the envelope -- the letter is legit. If it doesn't match -- someone tampered with it, or they don't know the secret word.

That's HMAC-SHA256 in a nutshell:
- **The shared secret** = your App Secret from the Meta dashboard
- **The letter** = the webhook request body (the JSON containing the message)
- **The blender** = SHA256 hash function
- **The signature on the envelope** = the `X-Hub-Signature-256` header that Meta includes

OpenClaw handles this automatically. When a webhook arrives, it:
1. Reads the `X-Hub-Signature-256` header
2. Takes the request body and your App Secret
3. Computes HMAC-SHA256
4. Compares the result to the header
5. If they match: process the message. If not: reject it silently.

> **The Bigger Picture:** This is the same concept behind HTTPS certificates, JWT tokens, and most of modern web security. If you understand HMAC, you understand the foundation of how the internet proves "this message is from who it claims to be from." That's a concept worth carrying beyond this course.

### Why This Matters

Without signature verification, anyone who discovers your webhook URL could:
- Send fake messages pretending to be from any phone number
- Trigger your bot to process arbitrary content (hello, prompt injection)
- Waste your Claude API credits with spam

With signature verification, only Meta can trigger your webhooks. Even if someone finds the URL (security through obscurity is not security, as we learned in Module 5), they can't forge the signature without your App Secret.

This is defense in depth at work. Your server already has zero open ports (Cloudflare Tunnel). Your secrets are properly managed (Docker Secrets). And now your webhook only accepts messages that are cryptographically proven to come from Meta. Three layers, each independent.

## The Phone Number Allowlist: Belt AND Suspenders

Even with signature verification, there's one more thing to think about. Your WhatsApp Business number is, well, a phone number. Anyone who knows it can message it. Meta will dutifully forward those messages to your webhook. And even though you've verified they're from Meta, do you really want random strangers talking to your Claude-powered bot?

Probably not. That's what the allowlist is for.

```yaml
whatsapp:
  allowed_numbers:
    - "+905551234567"    # your number
  block_unknown: true
```

With this configuration, OpenClaw will:
- Accept messages from numbers on the list
- Silently ignore messages from everyone else (no error response, no "you're not authorized" -- just silence)

Silent ignoring is intentional. If your bot responded with "You're not authorized," that would confirm to a stranger that the number is a working bot endpoint. Silence reveals nothing.

> **Pro tip:** During testing, your allowlist is basically just your own number. Later, you can add family members, a work phone, or a second device. But start small -- you can always add more.

## The Credentials: A Guided Tour

WhatsApp integration requires more credentials than any other service in this course. Here's what each one is and where to find it:

| Credential | What It Is | Where to Find It |
|---|---|---|
| **Phone Number ID** | Meta's internal ID for your test number (not the phone number itself) | Meta Dashboard > WhatsApp > Getting Started |
| **Business Account ID** | Meta's ID for your WhatsApp Business account | Meta Dashboard > WhatsApp > Getting Started |
| **Access Token (temporary)** | A short-lived token for testing (expires in ~24 hours) | Meta Dashboard > WhatsApp > Getting Started |
| **Access Token (permanent)** | A long-lived token for production use | Business Settings > System Users > Generate Token |
| **App Secret** | The shared secret for HMAC verification | App Settings > Basic > App Secret |
| **Webhook Verify Token** | A random string you make up for the verification handshake | You create this yourself |

Six credentials. That's a lot. The good news: you set them up once and then mostly forget about them (until the temporary token expires, which is why you'll want the permanent one).

## Test Mode vs Production

Meta gives you a sandbox to play in before you go live:

**Test mode (what we'll use):**
- You get a shared test phone number (not a real one you own)
- You can add up to 5 recipient phone numbers
- Messages are free
- No app review required
- The test number has a generic display name

**Production mode (optional, for later):**
- You register your own phone number
- Unlimited recipients
- Messages follow WhatsApp's pricing (free for the first 1,000 conversations per month)
- Requires app review by Meta (1-5 business days)
- Your business name shows up in the chat

For this module, test mode is all you need. You're the only person messaging your bot, and you just need to verify it works end-to-end. Going to production is a "nice to have" that we'll cover in the challenge, but it's entirely optional.

## What Could Go Wrong (And Usually Does)

Let me save you some debugging time. These are the issues I see most often:

1. **"Webhook verification failed"** -- Your verify token doesn't match. Copy-paste it exactly, no trailing spaces, no newlines.

2. **"Message sent but no response"** -- Check your OpenClaw logs. The webhook might be arriving but OpenClaw might not be processing it. Look for errors in `docker compose logs openclaw`.

3. **"Access token expired"** -- The temporary token lasts about 24 hours. If your bot suddenly stops working a day after setup, this is probably why. Generate a permanent token.

4. **"I can't find the webhook configuration page"** -- Meta moves things around. If the path I describe doesn't match what you see, look for "Configuration" or "Webhooks" in the WhatsApp product section of your app.

5. **"Webhook receives messages but signature verification fails"** -- Your App Secret doesn't match. Double-check you're using the App Secret (from Basic Settings), not the access token.

## Bringing It All Together

Let's zoom out. Here's what your security stack looks like after this module:

```
Internet
  |
  X (all ports blocked by UFW -- Module 5)
  |
  (but Cloudflare Tunnel bypasses this via outbound connection -- Module 7)
  |
  Cloudflare edge
  |
  Webhook arrives at OpenClaw
  |
  HMAC-SHA256 signature check (is this really from Meta? -- Module 8)
  |
  Phone number allowlist check (is this person approved? -- Module 8)
  |
  Secrets loaded from Docker Secrets, not .env (-- Module 6)
  |
  OpenClaw processes the message with Claude
```

Five layers. Each one independent. Even if one fails, the others still protect you. That's defense in depth -- not as a buzzword from Module 5, but as a real thing you built with your own hands.

Ready to set it up? Head to the [exercise](exercise.md) and let's wade through Meta's developer portal together.

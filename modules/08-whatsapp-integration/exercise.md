# Exercise: Connect WhatsApp to OpenClaw

## What We're Doing

We're creating a Meta developer account, setting up a WhatsApp Business app, configuring webhooks that route through your Cloudflare Tunnel, storing credentials as Docker Secrets, and sending your first WhatsApp message to your AI agent. It's a lot of steps, but we'll take them one at a time.

## Prerequisites

- A running VPS with Docker and Docker Compose
- A working Cloudflare Tunnel (from Module 7) with a domain like `openclaw.yourdomain.com`
- Docker Secrets set up (from Module 6)
- A phone with WhatsApp installed
- A Facebook account (you'll need one for Meta's developer portal -- a throwaway account works fine)
- About 90 minutes of focused time

---

## Part 1: Create a Meta Developer Account (~10 minutes)

**Step 1.** Open your browser and go to [https://developers.facebook.com](https://developers.facebook.com).

**Step 2.** Click **Get Started** or **Log In** (top right). Log in with your Facebook account.

If you don't have a Facebook account and don't want one -- fair enough, honestly -- you'll need to create one just for this. A minimal account with your name and email is sufficient. You don't need to add friends, post anything, or upload a photo.

**Step 3.** If prompted, accept the Meta Platform Terms and Developer Policies. You may also need to verify your account with a phone number or email.

**Step 4.** You should land on the Meta for Developers dashboard. It looks busy -- lots of panels, documentation links, and product cards. Don't worry about any of that yet.

> **If you see a "Complete Registration" prompt:** Follow it. Meta sometimes requires you to confirm your email or set up two-factor authentication before you can create apps. Just work through whatever they ask.

---

## Part 2: Create a WhatsApp Business App (~10 minutes)

**Step 5.** From the developer dashboard, click **Create App** (usually a green button near the top).

**Step 6.** You'll be asked what you want the app to do. Select **Other** and click **Next**.

> **Why "Other"?** Meta's app creation wizard tries to guide you toward specific use cases (gaming, business, etc.). "Other" gives you the most flexibility. We just need WhatsApp API access.

**Step 7.** For app type, select **Business**. Click **Next**.

**Step 8.** Fill in the app details:
- **App name:** `OpenClaw WhatsApp` (or whatever you like -- this is just for your reference)
- **App contact email:** your email address
- **Business Account:** If you have a Meta Business Account, select it. If not, select "I don't want to connect a business portfolio yet" -- you can do this later.

**Step 9.** Click **Create App**. You might need to re-enter your Facebook password.

**Step 10.** You should now be on your app's dashboard. It'll show a grid of products you can add. Find **WhatsApp** and click **Set Up**.

**Before you continue:** take a screenshot or bookmark this page. You'll come back to it several times.

---

## Part 3: Get Your WhatsApp Credentials (~10 minutes)

**Step 11.** After clicking Set Up on WhatsApp, you should be taken to the **WhatsApp > Getting Started** page (sometimes called "Quickstart" or "API Setup").

This page has three things you need. Let's grab them one by one.

**Step 12. Find your temporary Access Token.**

Look for a section labeled "Temporary access token" or "Access Token." There should be a token displayed (a long string of characters) with a Copy button. Copy it.

> **Important:** This token expires in about 24 hours. It's fine for testing today, but we'll generate a permanent one in the challenge. For now, just copy it and keep it handy.

**Step 13. Find your Phone Number ID.**

On the same Getting Started page, look for a section showing a test phone number. Below or beside it, you'll see a **Phone Number ID** -- a string of digits like `123456789012345`. Copy it.

This is NOT the phone number itself. It's Meta's internal identifier for the test number. You need this ID to send replies through the API.

**Step 14. Find your Business Account ID.**

Still on the same page (or sometimes under WhatsApp > Account), look for **WhatsApp Business Account ID** (also called WABA ID). It's another string of digits. Copy it.

**Step 15.** Open a text file or notes app and organize what you've collected so far:

```
WHATSAPP_ACCESS_TOKEN=EAAxxxxxxx (the long temporary token)
WHATSAPP_PHONE_NUMBER_ID=123456789012345
WHATSAPP_BUSINESS_ACCOUNT_ID=987654321098765
```

We'll store these properly as Docker Secrets in a few steps. For now, just keep them in your notes.

---

## Part 4: Get Your App Secret (~5 minutes)

**Step 16.** In the left sidebar of your app dashboard, go to **App Settings** > **Basic** (sometimes just called "Settings > Basic").

**Step 17.** Find the **App Secret** field. It'll be hidden behind a "Show" button. Click **Show**, enter your Facebook password if prompted, and copy the secret.

This is the shared secret used for HMAC-SHA256 webhook signature verification. It's arguably the most security-critical credential in this whole setup -- it's what proves incoming webhooks are actually from Meta.

**Step 18.** Add it to your notes:

```
WHATSAPP_APP_SECRET=abc123def456... (from App Settings > Basic)
```

---

## Part 5: Choose a Webhook Verify Token (~2 minutes)

**Step 19.** Generate a random string to use as your webhook verify token. This is a string *you* make up. On your VPS (or local machine), run:

```bash
openssl rand -hex 32
```

This gives you a 64-character random hex string. Copy it.

**Step 20.** Add it to your notes:

```
WHATSAPP_VERIFY_TOKEN=a1b2c3d4... (the random string you just generated)
```

> **Pro tip:** The verify token can technically be any string -- even "banana" would work. But using a long random string is better practice. If someone is trying to impersonate Meta's verification request, a random 64-character string is impossible to guess.

---

## Part 6: Store Credentials as Docker Secrets (~10 minutes)

Time to do this properly -- not in a `.env` file. You learned why in Module 6.

**Step 21.** SSH into your VPS:

```bash
ssh openclaw@YOUR_SERVER_IP
```

**Step 22.** Create the secret files. Run each command, replacing the placeholder with your actual value:

```bash
# Create the secrets directory if it doesn't exist
sudo mkdir -p /home/openclaw/secrets

# Store each credential
echo -n "YOUR_ACCESS_TOKEN" | sudo tee /home/openclaw/secrets/whatsapp_access_token > /dev/null
echo -n "YOUR_PHONE_NUMBER_ID" | sudo tee /home/openclaw/secrets/whatsapp_phone_number_id > /dev/null
echo -n "YOUR_BUSINESS_ACCOUNT_ID" | sudo tee /home/openclaw/secrets/whatsapp_business_account_id > /dev/null
echo -n "YOUR_APP_SECRET" | sudo tee /home/openclaw/secrets/whatsapp_app_secret > /dev/null
echo -n "YOUR_VERIFY_TOKEN" | sudo tee /home/openclaw/secrets/whatsapp_verify_token > /dev/null
```

The `echo -n` flag is important -- it prevents a trailing newline from being added to the secret. A stray newline in an API token will cause mysterious authentication failures that will eat an hour of your life.

**Step 23.** Lock down the permissions:

```bash
sudo chmod 600 /home/openclaw/secrets/whatsapp_*
sudo chown openclaw:openclaw /home/openclaw/secrets/whatsapp_*
```

**Step 24.** Verify the files exist and have the right permissions:

```bash
ls -la /home/openclaw/secrets/whatsapp_*
```

You should see five files, all with `-rw-------` permissions (readable only by the owner).

**Step 25.** Update your `docker-compose.yml` to reference these secrets. Open the file:

```bash
nano /home/openclaw/docker-compose.yml
```

Add the WhatsApp secrets to the `secrets` section (create it if it doesn't exist):

```yaml
secrets:
  whatsapp_access_token:
    file: ./secrets/whatsapp_access_token
  whatsapp_phone_number_id:
    file: ./secrets/whatsapp_phone_number_id
  whatsapp_business_account_id:
    file: ./secrets/whatsapp_business_account_id
  whatsapp_app_secret:
    file: ./secrets/whatsapp_app_secret
  whatsapp_verify_token:
    file: ./secrets/whatsapp_verify_token
```

And reference them in the OpenClaw service:

```yaml
services:
  openclaw:
    # ... existing config ...
    secrets:
      - whatsapp_access_token
      - whatsapp_phone_number_id
      - whatsapp_business_account_id
      - whatsapp_app_secret
      - whatsapp_verify_token
```

Save and close (`Ctrl+O`, `Enter`, `Ctrl+X` in nano).

> **Before you continue:** If you're not sure how to edit Docker Compose files, review Module 6. The `starter/` directory for this module also has a sample `docker-compose.yml` snippet you can reference.

---

## Part 7: Configure the Webhook (~15 minutes)

This is the part where everything connects. Make sure your Cloudflare Tunnel is running before you proceed.

**Step 26.** Verify your tunnel is active. On your VPS:

```bash
docker compose ps
```

You should see the `cloudflared` container running. If not, bring it up:

```bash
docker compose up -d cloudflared
```

**Step 27.** Also make sure OpenClaw is running:

```bash
docker compose up -d openclaw
```

**Step 28.** Go back to the Meta developer portal in your browser. Navigate to your app, then in the left sidebar: **WhatsApp** > **Configuration** (sometimes called "Webhooks" or found under the WhatsApp product section).

**Step 29.** Find the **Webhook** section. Click **Edit** (or **Configure Webhook** if it hasn't been set up yet).

**Step 30.** Fill in:
- **Callback URL:** `https://openclaw.yourdomain.com/webhook/whatsapp`
  (replace `yourdomain.com` with your actual domain from Module 7)
- **Verify Token:** paste the random string from Step 19

**Before you click Verify:** what do you think will happen?

Here's what *should* happen: Meta will send a GET request to your callback URL. The request will hit Cloudflare's edge, travel through your tunnel, arrive at OpenClaw, and OpenClaw will check the verify token. If it matches, OpenClaw responds with the challenge, and Meta marks the webhook as verified.

**Step 31.** Click **Verify and Save**.

If it works, you'll see a success message. The webhook is now configured.

**If verification fails:**

Don't panic. This is the most common failure point, and it's almost always one of these:

1. **Tunnel isn't running.** Check `docker compose ps` -- is cloudflared healthy?
2. **OpenClaw isn't running.** Check `docker compose ps` -- is openclaw healthy?
3. **Wrong URL.** Double-check your domain. It needs to be exactly the subdomain you configured in Cloudflare Tunnel.
4. **Verify token mismatch.** Make sure the token in the Meta portal matches the one in your secret file exactly. Check for trailing spaces or newlines: `cat -A /home/openclaw/secrets/whatsapp_verify_token` (the output should NOT end with `$` preceded by a space or newline character).
5. **DNS not propagated.** If you just set up the tunnel, DNS might not have propagated yet. Wait 5 minutes and try again.

**Step 32.** After successful verification, you need to subscribe to webhook events. On the same Configuration page, find the **Webhook fields** section. Click **Manage** (or look for checkboxes next to field names).

**Step 33.** Find **messages** in the list and click **Subscribe** (or check the checkbox). This tells Meta to send you webhooks when messages arrive.

You might see other fields like `message_deliveries`, `message_reads`, etc. You only need `messages` for now. Subscribe to that one.

---

## Part 8: Add Your Phone Number as a Test Recipient (~5 minutes)

Meta's test phone number can only send messages to pre-approved numbers. Let's add yours.

**Step 34.** In the Meta developer portal, go to **WhatsApp** > **Getting Started** (or "API Setup").

**Step 35.** Look for a section called **"To" number** or **"Add phone number."** Click **Manage phone number list** or **Add a phone number**.

**Step 36.** Enter your WhatsApp phone number in international format (e.g., `+905551234567`). Include the country code with the `+` prefix.

**Step 37.** Meta will send a verification code to your WhatsApp. Enter the code to confirm.

Your number is now approved as a test recipient. You can add up to 5 numbers in test mode.

---

## Part 9: Send a Test Message (~10 minutes)

Let's verify the full flow works, end to end.

**Step 38.** First, send a template message from Meta to your phone. This is required -- WhatsApp requires a business to send the first message using an approved template before you can have a free-form conversation.

On the **Getting Started** page, there should be a **"Send Message"** section with a pre-built "hello_world" template. Select your phone number from the "To" dropdown and click **Send Message**.

**Step 39.** Check your WhatsApp. You should receive a template message from the test number (something like "Hello World" or a greeting in your language).

**Step 40.** Now reply to that message. Type anything:
- "Hello, are you there?"
- "What can you do?"
- "Tell me a joke"

**Before you send it:** Trace the path in your head. Your message will go from your phone to Meta's servers, then Meta will POST it to your webhook URL, Cloudflare will route it through the tunnel, OpenClaw will verify the signature, check the allowlist, process it with Claude, and send the reply back through Meta's API. That's the whole flow you just built.

**Step 41.** Send it and watch.

If everything is working, you'll get a response within a few seconds. Your AI agent is now on WhatsApp.

> **If you get no response:** Check the OpenClaw logs:
> ```bash
> docker compose logs --tail=50 openclaw
> ```
> Look for incoming webhook events, signature verification results, or error messages. The logs will tell you exactly where things broke.

---

## Part 10: Verify the Security Layers (~5 minutes)

Let's confirm all the security layers are actually working.

**Step 42.** Check that signature verification is active. Look at the OpenClaw logs for successful verification:

```bash
docker compose logs openclaw | grep -i "signature\|webhook\|verified"
```

You should see log entries indicating incoming webhooks and successful signature verification.

**Step 43.** Test that your tunnel is the only way in. From your laptop (not the VPS), try to directly access OpenClaw on the server's IP:

```bash
curl -s http://YOUR_SERVER_IP:3000/webhook/whatsapp
```

This should time out or fail with "connection refused." Your firewall is blocking direct access -- the only way in is through the tunnel. That's exactly what we want.

**Step 44.** Check that your secrets aren't exposed in Docker's environment:

```bash
docker inspect openclaw 2>/dev/null | grep -i "whatsapp"
```

If you set up Docker Secrets correctly (file-based, not environment variables), this should return nothing -- your WhatsApp credentials are in `/run/secrets/` inside the container, not in the environment.

---

## What Just Happened?

Let's take stock of what you built in this exercise:

- **Meta developer account** with a WhatsApp Business app
- **Webhook configuration** pointing at your Cloudflare Tunnel URL
- **Six credentials** stored as Docker Secrets with locked-down file permissions
- **Webhook signature verification** (HMAC-SHA256) active and working
- **End-to-end message flow** from your WhatsApp to Claude and back

Your security stack:

| Layer | Status |
|---|---|
| Firewall (UFW) | Blocking all inbound except SSH |
| Cloudflare Tunnel | Only route in for webhooks |
| HMAC-SHA256 signatures | Rejecting non-Meta requests |
| Docker Secrets | Credentials invisible to `docker inspect` |
| Phone allowlist | (Coming in the challenge) |

That's four layers of defense already active, with a fifth coming in the challenge.

---

## Try This (Optional Experiments)

1. **Check the raw webhook payload.** Look at your OpenClaw logs right after sending a message. You'll see the JSON that Meta sends -- it contains the sender's phone number, the message text, a timestamp, and the message type. Understanding this payload structure helps when debugging.

2. **Send different message types.** Try sending a photo, a voice note, or a location to your bot. Check the logs to see how different message types appear in the webhook payload. OpenClaw may or may not handle all of them -- it depends on how it's configured.

3. **Check the Meta dashboard.** Go to WhatsApp > Insights (or Analytics) in the Meta developer portal. You should see your test messages reflected in the metrics. This dashboard becomes useful when you're monitoring usage in production.

4. **Watch the tunnel traffic.** Check the Cloudflare Zero Trust dashboard (from Module 7). You should see the webhook requests showing up in the tunnel's activity log -- proof that traffic is flowing through the tunnel as expected.

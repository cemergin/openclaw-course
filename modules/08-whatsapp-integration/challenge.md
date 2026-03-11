# Challenge: Lock It Down and Go Live

## The Scenario

Your WhatsApp integration works. You can message your bot and get responses from Claude. But right now, anyone who discovers your WhatsApp Business number could message it too -- and you'd be paying for their Claude API usage. In a production environment, you'd also want a permanent access token (the temporary one expires in 24 hours), app review approval from Meta, and confidence that your security layers are actually doing their job.

Your mission: harden the integration, verify your defenses, and optionally prepare for production.

## Task 1: Configure the Phone Number Allowlist

Set up OpenClaw to only respond to your phone number. Messages from any other number should be silently ignored.

**Success criteria:**
- Your number gets responses
- Any other number is silently dropped (no error, no response)
- The allowlist is configured in a file, not hardcoded

<details>
<summary>Hint 1: Where does the allowlist go?</summary>

Look at OpenClaw's configuration file (often `config.yaml` or similar). There should be a `whatsapp` section where you can define `allowed_numbers` and `block_unknown`.

</details>

<details>
<summary>Hint 2: What format do the phone numbers need to be in?</summary>

International format with the `+` prefix and country code. For example: `+905551234567`, `+14155552671`. No spaces, no dashes. This must match exactly what Meta sends in the webhook payload -- check your logs to see the exact format of the sender's number.

</details>

<details>
<summary>Hint 3: Almost there...</summary>

Add this to your OpenClaw configuration:

```yaml
whatsapp:
  allowed_numbers:
    - "+905551234567"    # replace with your actual number
  block_unknown: true
```

Then restart OpenClaw: `docker compose restart openclaw`. Test by sending a message from your number (should work) and then, if you can, have someone else message the bot (should get no response).

</details>

## Task 2: Verify Signature Validation Is Working

Prove that your webhook rejects unsigned requests -- not just trust that it does.

**Success criteria:**
- A legitimate WhatsApp message is accepted and processed
- A manually crafted POST to your webhook URL (without a valid signature) is rejected
- You can see the rejection in the logs

<details>
<summary>Hint 1: How do you send a fake webhook?</summary>

Use `curl` from your VPS to send a POST directly to OpenClaw's local port (bypassing the tunnel). This simulates someone sending a request without a valid Meta signature.

</details>

<details>
<summary>Hint 2: What should the curl command look like?</summary>

```bash
curl -X POST http://localhost:3000/webhook/whatsapp \
  -H "Content-Type: application/json" \
  -d '{"entry":[{"changes":[{"value":{"messages":[{"from":"5551234567","text":{"body":"fake message"}}]}}]}]}'
```

This has no `X-Hub-Signature-256` header. OpenClaw should reject it.

</details>

<details>
<summary>Hint 3: Where to check for the rejection?</summary>

Check the logs immediately after sending the fake request:

```bash
docker compose logs --tail=20 openclaw
```

You should see something indicating a signature verification failure or an unauthorized request. The exact log message depends on OpenClaw's implementation, but look for "signature," "unauthorized," "invalid," or "rejected."

</details>

## Task 3: Explore the Meta Dashboard

Get familiar with the monitoring tools Meta provides. You'll need these when debugging issues in production.

**Success criteria:**
- You can find the webhook delivery logs in the Meta dashboard
- You can see your test messages in WhatsApp Insights
- You know where to check webhook failure rates

**Where to look:**
1. In your app dashboard, go to **WhatsApp > Insights** for message analytics
2. Go to **Webhooks > Test** to see recent webhook deliveries and their HTTP status codes
3. Go to **App Dashboard > Alerts** to see if Meta flagged any issues

This task has no hidden solution -- it's about exploration. Spend 10 minutes clicking around. The Meta dashboard is messy, but knowing where things are will save you hours of debugging later.

## Task 4: Plan for Production (Optional)

If you want to move beyond the test sandbox, here's what's involved. You don't need to do this today, but understanding the path is valuable.

### Generate a Permanent Access Token

The temporary token from the Getting Started page expires in ~24 hours. For production, you need a permanent one:

1. Go to [business.facebook.com](https://business.facebook.com) > **Business Settings**
2. Under **Users**, go to **System Users**
3. Click **Add** to create a new system user
   - Name: `openclaw-api`
   - Role: **Admin** (needed for messaging permissions)
4. Click **Generate Token** on the new system user
5. Select your WhatsApp app
6. Grant the `whatsapp_business_messaging` permission
7. Click **Generate Token**
8. Copy the new permanent token

Then update your Docker Secret:

```bash
echo -n "YOUR_NEW_PERMANENT_TOKEN" | sudo tee /home/openclaw/secrets/whatsapp_access_token > /dev/null
sudo chmod 600 /home/openclaw/secrets/whatsapp_access_token
docker compose restart openclaw
```

### Submit for App Review

To use a real phone number and message anyone (not just 5 test numbers):

1. Go to your app dashboard > **App Review** > **Requests**
2. Request the `whatsapp_business_messaging` permission
3. You'll need to provide:
   - A description of what your app does
   - A privacy policy URL (can be a simple page on your domain)
   - Instructions for Meta's reviewers to test your app
4. Submit and wait 1-5 business days

### Register a Real Phone Number

After app review approval:

1. Go to **WhatsApp** > **Getting Started** > **Add phone number**
2. Enter the phone number you want to use as your bot's number
   (Note: this number can NOT already be registered on regular WhatsApp)
3. Verify via SMS or voice call
4. Your bot now has its own dedicated number

> **Trade-off:** For personal use, test mode with 5 numbers is often enough. You get your number, a family member's number, maybe a work phone. Going to production adds complexity (app review, privacy policy, a dedicated phone number) that you may not need. But if you want to share your bot more broadly or have a clean display name in chats, production is the way to go.

---

## Solution

<details>
<summary>Full solution for Tasks 1-2</summary>

### Task 1: Phone Allowlist

Add to your OpenClaw configuration (the exact file depends on your setup -- check `config.yaml`, `openclaw.yaml`, or the configuration mounted in your Docker Compose):

```yaml
whatsapp:
  allowed_numbers:
    - "+905551234567"    # your primary number
  block_unknown: true
```

Restart to apply:

```bash
docker compose restart openclaw
```

Verify by sending a message from your number:

```bash
# Watch the logs in real-time
docker compose logs -f openclaw
```

Send a WhatsApp message. You should see it being received and processed. If you can test from a non-listed number, you should see either a log entry saying the number was blocked, or simply no processing at all.

### Task 2: Signature Verification

Send a fake webhook without a signature:

```bash
curl -X POST http://localhost:3000/webhook/whatsapp \
  -H "Content-Type: application/json" \
  -d '{"object":"whatsapp_business_account","entry":[{"id":"123","changes":[{"value":{"messaging_product":"whatsapp","metadata":{"display_phone_number":"15551234567","phone_number_id":"123456"},"messages":[{"from":"905551234567","id":"wamid.test","timestamp":"1234567890","text":{"body":"This is a fake message"},"type":"text"}]},"field":"messages"}]}]}'
```

Then check the logs:

```bash
docker compose logs --tail=10 openclaw
```

You should see the request being rejected due to missing or invalid signature. Compare this to the logs from a real WhatsApp message (which shows successful verification). The difference is your proof that signature verification is working.

### Why This Matters

The allowlist and signature verification together create two independent security checks:

1. **Signature verification** answers: "Did this webhook actually come from Meta?" (Blocks forged requests)
2. **Phone allowlist** answers: "Is this person allowed to talk to my bot?" (Blocks unauthorized users even if they message the real WhatsApp number)

Neither alone is sufficient. Together, they're solid. Add the Cloudflare Tunnel and UFW firewall from earlier modules, and you've got four layers of defense. That's not paranoia -- that's engineering.

</details>

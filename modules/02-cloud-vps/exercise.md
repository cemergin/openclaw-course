# Exercise: Launch Your Lightsail Instance

## What We're Doing

We're creating an AWS account (if you don't have one), spinning up an Ubuntu server on Lightsail, locking down the firewall, and attaching a static IP. By the end, you'll have a running server with an IP address you can write down -- that's *your* server.

## Prerequisites

- A web browser
- A credit card (for AWS signup -- you won't be charged until the free trial ends or you exceed free tier)
- A phone number (for AWS verification)
- About 15-20 minutes

---

## Part 1: Create an AWS Account

*If you already have an AWS account, skip to Part 2.*

**Step 1.** Open your browser and go to [https://aws.amazon.com](https://aws.amazon.com). Click **Create an AWS Account** (top right).

**Step 2.** Enter your email address and choose an account name. This can be anything -- "My OpenClaw Server" works fine. Click **Verify email address**.

**Step 3.** Check your email for a verification code. Enter it.

**Step 4.** Set a strong password. Write it down or save it in a password manager. You'll need this again.

**Step 5.** Choose **Personal** for the account type. Fill in your contact information.

**Step 6.** Enter your credit card information. AWS won't charge you yet -- this is just for verification and future billing.

**Step 7.** Verify your phone number. AWS will either call you or send an SMS with a code.

**Step 8.** Choose the **Basic (Free)** support plan. You don't need paid support.

**Step 9.** You should land on the AWS Console dashboard. Take a breath -- the hard part is over. That was mostly just filling out forms.

---

## Part 2: Navigate to Lightsail

**Step 10.** Go directly to [https://lightsail.aws.amazon.com](https://lightsail.aws.amazon.com). This is Lightsail's own console -- much simpler than the main AWS console.

> **Pro tip:** Bookmark this URL. The main AWS console has about a thousand services. Lightsail has its own, cleaner interface, and you'll rarely need to leave it.

**Step 11.** If this is your first time on Lightsail, you may see a welcome screen. Click through it. You'll land on the Lightsail home page, which should be mostly empty.

---

## Part 3: Create Your Instance

**Step 12.** Click **Create instance**.

**Step 13.** Under **Instance location**, pick the region closest to you. If you're in Europe, pick a European region (e.g., Frankfurt, London, Paris). If you're in the US, us-east-1 (Virginia) is a solid default. If you're in Asia-Pacific, pick Singapore or Tokyo.

*Why does region matter?* Latency. Your WhatsApp messages will travel to this server and back. Closer = faster responses. It won't matter much for text messages, but it's free to pick a close region, so why not.

**Step 14.** Under **Pick your instance image**:
- Select **Linux/Unix** as the platform
- Select **OS Only**
- Select **Ubuntu 22.04 LTS**

We want a clean Ubuntu installation -- no pre-installed apps. We'll install everything ourselves with Docker in Module 4.

> **Before you continue:** Why Ubuntu 22.04 and not the latest version? LTS stands for Long Term Support -- it gets security updates for 5 years. Newer versions are fine too, but 22.04 is the most widely tested with the tools we'll use. If 24.04 LTS is available and you prefer it, that works too.

**Step 15.** Scroll down to **Choose your instance plan**. Select the **$10/month** plan (1 vCPU, 2GB RAM, 60GB SSD).

Check if there's a free trial badge on any of the plans. New Lightsail users often get the first 3 months of the $5 plan free, or sometimes the first month of higher plans. If you see a free trial on the $10 plan, even better.

If $10/month is too much right now, the $5 plan will work -- you'll just need to be more careful about resource usage when we add SearXNG and monitoring later.

**Step 16.** Under **Identify your instance**, give it a name. Something like `openclaw-01` or `my-ai-agent`. Keep it short and lowercase -- you'll type this name occasionally.

**Step 17.** Click **Create instance**.

**Step 18.** Wait about 30-60 seconds. Your instance will show as "Pending" and then switch to "Running." You now have a server.

Let that sink in for a second. Somewhere in a data center, a computer just booted up, and it's yours to use. It's running Ubuntu, it has an IP address, and it's waiting for you to tell it what to do.

---

## Part 4: Configure the Firewall

This is the step most tutorials skip, and it's arguably the most important thing you'll do today.

**Step 19.** Click on your instance name to open its detail page.

**Step 20.** Click the **Networking** tab.

**Step 21.** Scroll down to the **IPv4 Firewall** section. You should see something like this:

| Application | Protocol | Port range |
| --- | --- | --- |
| SSH | TCP | 22 |
| HTTP | TCP | 80 |
| HTTPS | TCP | 443 |

**Step 22.** **Delete the HTTP rule.** Click the three dots (or trash icon) next to the HTTP row and remove it.

**Step 23.** **Delete the HTTPS rule.** Same thing -- remove it.

**Step 24.** You should now have **only one firewall rule**:

| Application | Protocol | Port range |
| --- | --- | --- |
| SSH | TCP | 22 |

This is exactly what we want. Your server is now invisible to the internet except for SSH. No one can reach port 80 or 443. When we set up Cloudflare Tunnel in Module 7, webhooks will reach your server through an *outbound* connection -- the server calls out to Cloudflare, not the other way around. No inbound ports needed.

> **Why this matters:** Every open port is a door. We just closed two doors we don't need. This is the "start locked down" philosophy you'll hear us repeat throughout the course. In Module 5, we'll go deeper on why this matters and set up additional layers of protection.

---

## Part 5: Attach a Static IP

**Step 25.** Still on the **Networking** tab, scroll up to the **Public IPv4 address** section.

**Step 26.** You'll see your instance's current IP address. Notice the note that says it will change if you stop and restart the instance. Let's fix that.

**Step 27.** Click **Attach static IP** (or navigate to the Networking tab's static IP section).

**Step 28.** Give your static IP a name, like `openclaw-ip`.

**Step 29.** Make sure your instance is selected in the dropdown, and click **Create and attach**.

**Step 30.** You now have a static IP address. **Write it down.** You'll need this for every module going forward. It looks something like `18.194.123.45` (four groups of numbers separated by dots).

This IP address is now permanently yours (as long as you keep the instance running). Stop the instance, start it again -- same IP. This is crucial for DNS records, SSH configs, and your own sanity.

> **Pro tip:** Put this IP address somewhere easy to find. A note on your phone, a sticky note on your monitor, a pinned message in your notes app. You'll type it a lot in the next few modules.

---

## What Just Happened?

Let's take stock of what you now have:

- **An AWS account** -- your gateway to cloud services
- **A Lightsail instance** -- an Ubuntu 22.04 server running in a data center, 24/7
- **A locked-down firewall** -- only SSH (port 22) is allowed in. No web traffic, no surprises.
- **A static IP address** -- a permanent address that won't change

You can't actually *do* anything with the server yet -- we haven't connected to it. That's what Module 3 (SSH and Linux Basics) is for. But the server is running, secured, and ready.

Your monthly cost: **$10/month** for the instance. The static IP is free. That's it.

---

## Try This (Optional Experiments)

1. **Look at the Metrics tab.** Click on your instance and go to the Metrics tab. You'll see CPU utilization, network in/out, and status checks. Right now it's basically at zero -- nobody's home yet. After we deploy OpenClaw, you'll be able to see actual usage here.

2. **Try the browser-based SSH.** Lightsail has a built-in SSH terminal. On your instance's detail page, click the orange "Connect using SSH" button. A terminal will open in your browser. Type `whoami` and press Enter. You should see `ubuntu`. Type `exit` to close. (We'll set up proper SSH with keys in Module 3 -- this browser terminal is just for quick checks.)

3. **Check the IPv6 firewall too.** Lightsail also has an IPv6 firewall section. If you see default rules there, delete the HTTP and HTTPS ones just like you did for IPv4. Keep SSH only.

# Challenge: Know Your Server

## The Scenario

Your instance is running, but you haven't really *explored* it yet. Before we move on to SSH and Linux, let's make sure you actually understand what you're paying for and where to find important things in the Lightsail dashboard. Think of this as learning where the fire extinguisher, fuse box, and water shutoff are in a new apartment -- boring but important.

You'll also do a quick comparison with another provider, because knowing your options is part of being a competent server operator.

## Your Tasks

### Task 1: Find the Snapshots Section

Snapshots are point-in-time backups of your entire instance. If something goes catastrophically wrong later (bad config, corrupted disk, accidental `rm -rf /`), a snapshot lets you roll back to a known good state.

**Find where snapshots live in the Lightsail console.** Answer these questions:

1. Where is the Snapshots section? (Which tab on your instance page?)
2. Can you enable *automatic* snapshots? What does it cost?
3. If you created a manual snapshot right now, could you use it to launch a brand new instance?

### Task 2: Read the Metrics Tab

Your instance is basically idle right now, but the metrics tab still has useful information.

**Open the Metrics tab and find:**

1. What is your CPU utilization right now? (Should be very low)
2. What are the available metric types? (List them)
3. What time range is shown by default? Can you change it?

### Task 3: Explore the Networking Page

You already configured the firewall, but the Networking tab has more to offer.

**Go back to the Networking tab and answer:**

1. What's the difference between your public IP and your private IP?
2. Does your instance have an IPv6 address?
3. If you scroll down, is there a DNS zone section? What would that be for?

### Task 4: Estimate Your Monthly Cost

Using what you learned in the lesson and what you can see in the Lightsail console:

**Calculate the estimated monthly cost of running your setup with:**

- The $10 instance plan
- A static IP (attached)
- Automatic snapshots enabled
- No other Lightsail resources

Write it down. We'll revisit this number in Module 9 when we estimate the *total* cost including API usage.

### Bonus Task: Compare with Hetzner

This one's optional, but it's a great exercise in knowing your options.

**Go to [https://www.hetzner.com/cloud](https://www.hetzner.com/cloud) and find the CAX11 plan.** Answer:

1. What are the specs (vCPU, RAM, storage, bandwidth)?
2. What's the monthly price?
3. How does it compare to your Lightsail $10 plan? (Specs vs. price)
4. What's the catch? (Hint: data center locations, architecture type)

---

## Hints

<details>
<summary>Hint 1: Where to find snapshots</summary>

Click on your instance name in the Lightsail console. Look at the tabs along the top of the instance detail page. Snapshots has its own tab. Automatic snapshots are a toggle you can enable -- they run daily and cost $0.05/GB per month of the snapshot size (roughly $2.50/month for a typical instance).

</details>

<details>
<summary>Hint 2: Networking details</summary>

Your **public IP** is the address the internet uses to reach your server. Your **private IP** is the address used for internal communication between Lightsail resources in the same region. Think of it like your street address (public) vs. your apartment number (private). IPv6 availability depends on your region -- some regions assign one automatically.

</details>

<details>
<summary>Hint 3: Hetzner comparison</summary>

The Hetzner CAX11 offers 2 vCPU (ARM/Ampere), 4GB RAM, 40GB disk, and 20TB bandwidth for about EUR 3.79/month. Compare that to Lightsail's $10 plan: 1 vCPU, 2GB RAM, 60GB SSD, 3TB bandwidth. Hetzner gives you double the CPU and RAM for less than half the price. The trade-offs: Hetzner data centers are EU-only (Falkenstein, Nuremberg, Helsinki), the CPUs are ARM (not x86), and the company is less well-known than AWS. For our use case, none of those are dealbreakers -- ARM works perfectly fine with Docker and all our tools.

</details>

---

## Solution

<details>
<summary>Click to reveal full answers</summary>

### Task 1: Snapshots

1. **Snapshots tab** on the instance detail page (alongside Connect, Storage, Metrics, Networking, Tags, History, Delete)
2. Yes -- there's an "Enable automatic snapshots" toggle. It costs **$0.05/GB per month** of snapshot storage. For a $10 instance with ~60GB disk (though actual usage will be much less), expect roughly **$1-3/month**. Lightsail also shows an estimate before you enable it.
3. Yes -- from a snapshot, you can create a brand new instance. This is effectively disaster recovery. You'd get an identical copy of your server at the moment the snapshot was taken.

### Task 2: Metrics

1. CPU utilization should be near **0-2%** -- the instance is running but nothing is happening on it yet.
2. Available metrics typically include: **CPU utilization**, **Network in (bytes)**, **Network out (bytes)**, **Status check failed** (instance), and **Status check failed** (system).
3. Default is usually **last 24 hours**. You can switch to 1 hour, 6 hours, 1 day, 1 week, or 2 weeks.

### Task 3: Networking

1. **Public IP** is your internet-facing address (e.g., 18.194.x.x) -- what the world uses to reach you. **Private IP** (e.g., 172.26.x.x) is for communication between Lightsail instances in the same region. It's not accessible from the internet.
2. Depends on your region. Many regions now assign an IPv6 address automatically. If you have one, it'll be shown on the Networking tab.
3. Lightsail has a DNS zone feature for managing domain name records. We won't use it -- we'll use Cloudflare for DNS in Module 7. But it's there if you want to keep everything inside AWS.

### Task 4: Monthly Cost

| Item | Cost |
| --- | --- |
| $10 instance plan | $10.00 |
| Static IP (attached) | $0.00 |
| Automatic snapshots | ~$2.50 |
| **Total** | **~$12.50/month** |

This does NOT include AI API costs (Claude/OpenAI), which we'll estimate in Module 9. The infrastructure alone is about $12.50.

### Bonus: Hetzner Comparison

| | Lightsail $10 | Hetzner CAX11 |
| --- | --- | --- |
| **vCPU** | 1 | 2 (ARM) |
| **RAM** | 2 GB | 4 GB |
| **Storage** | 60 GB SSD | 40 GB SSD |
| **Bandwidth** | 3 TB | 20 TB |
| **Price** | $10/month | ~$4/month |
| **Data centers** | Worldwide | EU only |
| **Architecture** | x86 | ARM (Ampere) |

Hetzner is genuinely better value. The reason we use Lightsail is simplicity and worldwide availability, not price. If you're in Europe and comfortable with a less familiar provider, Hetzner is the smart money move. Everything in this course works on either -- Docker doesn't care which cloud you're on.

</details>

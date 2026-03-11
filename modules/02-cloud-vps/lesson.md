# Your Computer in the Sky

## Provisioning a VPS on AWS Lightsail

---

Have you ever left your laptop running overnight so a download could finish? Or kept a script going while you slept? Now imagine a computer that *never* needs to sleep, never loses its internet connection, and sits in a climate-controlled building with redundant power and a network connection faster than anything you have at home.

That's what we're renting today.

## What Is a VPS, Really?

A **VPS** -- Virtual Private Server -- is a computer in a data center that you rent by the month. "Virtual" because the physical machine is shared with other renters (like apartments in a building), but your slice is completely isolated. You get your own operating system, your own storage, your own IP address. Nobody else can see your stuff, and you can't see theirs.

Think of it like this: buying a physical server is like buying a house. A VPS is like renting an apartment. You get your own space, your own keys, and you can decorate however you want -- but someone else handles the plumbing, the electricity, and the roof.

For our purposes, the VPS is where OpenClaw will live. It runs 24/7, so your AI agent is always available. You message it at 3am from your phone? The VPS is awake, processing your request, calling the Claude API, and sending back a response. Your laptop can be off. Your phone can be on airplane mode after sending. The VPS handles everything.

> **The Bigger Picture:** Every web service you use -- Gmail, Netflix, Slack -- runs on servers in data centers. What we're doing isn't exotic. We're just doing it ourselves instead of paying someone else's markup. That's the whole self-hosting philosophy.

## The Cloud Provider Landscape

There are dozens of companies that will rent you a VPS. Here are the ones worth knowing about:

| Provider | Cheapest Useful Plan | Specs | Notes |
| --- | --- | --- | --- |
| **AWS Lightsail** | $5/mo | 1 vCPU, 1GB RAM, 40GB SSD | Simplest AWS option. Predictable pricing. |
| **Hetzner CAX11** | ~$4/mo | 2 vCPU, 4GB RAM, 40GB SSD | Best value. ARM-based. EU data centers. |
| **DigitalOcean** | $6/mo | 1 vCPU, 1GB RAM, 25GB SSD | Popular with developers. Good docs. |
| **Vultr** | $6/mo | 1 vCPU, 1GB RAM, 25GB SSD | Similar to DigitalOcean. |
| **Linode (Akamai)** | $5/mo | 1 vCPU, 1GB RAM, 25GB SSD | Solid option. Recently acquired. |

If you're purely optimizing for price-to-performance, Hetzner's CAX11 is absurd -- you get 2 vCPUs and 4GB of RAM for about four dollars a month. It's ARM-based (same architecture as your phone and Apple Silicon Macs), and everything we're running works fine on ARM.

So why are we using Lightsail?

## Why Lightsail

Three reasons:

**1. Simplicity.** Lightsail is AWS's "just give me a server" product. Regular AWS (EC2) is like walking into a restaurant with a 47-page menu. Lightsail is the daily special. You pick a size, click create, and you're done. No VPCs, no security groups, no IAM policies -- just a server.

**2. Predictable pricing.** With regular AWS, you can accidentally spin up resources that cost hundreds of dollars. Lightsail has flat monthly pricing. The $10 plan costs $10. Period. No bandwidth surprises, no hidden fees, no "we charged you $847 because you left a load balancer running." The price ceiling is the price.

**3. Good enough.** For a personal AI agent, Lightsail has everything we need. If you outgrow it someday, you can always migrate. But most people running OpenClaw for personal use will never need to.

> **Pro tip:** If you're not in the US or prefer European data centers, Hetzner is genuinely excellent. The steps in this course will work on any Ubuntu VPS -- we're using Lightsail as the reference, but the concepts are universal. Swap the provider and everything else stays the same.

## Picking the Right Size

Your VPS needs enough resources to run OpenClaw plus the supporting services (Cloudflare Tunnel, optionally SearXNG for web search, optionally Uptime Kuma for monitoring). Here's how the Lightsail plans map to our needs:

| Plan | Specs | Good For |
| --- | --- | --- |
| **$5/mo** | 1 vCPU, 1GB RAM, 40GB SSD | OpenClaw + tunnel only. Tight but works. |
| **$10/mo** | 1 vCPU, 2GB RAM, 60GB SSD | OpenClaw + tunnel + SearXNG + monitoring. Comfortable. |
| **$20/mo** | 2 vCPU, 4GB RAM, 80GB SSD | Everything above + room to add more integrations later. |

**We recommend the $10 plan.** It gives you breathing room for the full stack we'll build in this course (OpenClaw, Cloudflare Tunnel, SearXNG, Uptime Kuma) without feeling cramped. The extra gigabyte of RAM matters more than you'd think when you're running multiple Docker containers.

The $5 plan works if you're watching every dollar -- you just won't be able to run SearXNG and Uptime Kuma alongside OpenClaw without things getting tight. And the $20 plan is nice to have but overkill for most personal setups.

> **Pro tip:** AWS often offers a free trial for Lightsail -- typically the first month of the smallest plan is free, and sometimes the first three months. Check the current offer at signup. Even without a trial, you're looking at $10/month. That's less than most streaming subscriptions, and this one actually does something useful.

## Static vs. Dynamic IPs

When you create a Lightsail instance, it gets an IP address. But here's the thing: that IP address can *change* every time you stop and restart the instance. This is called a **dynamic IP**, and it's a headache. You'd have to update your DNS records, your SSH config, and anything else that points to your server every time it gets a new address.

A **static IP** is a permanent address that stays the same no matter what. On Lightsail, static IPs are free as long as they're attached to a running instance. There's literally no reason not to use one.

We'll attach one during the exercise.

## A Word About the Firewall

Lightsail instances come with a built-in firewall, and by default it allows HTTP (port 80) and HTTPS (port 443) traffic in. That's fine for a web server, but we're not running a web server -- at least not one that should be publicly accessible.

In Module 5 (Security Fundamentals), we'll talk about this in detail. For now, here's what you need to know: **we're going to remove those default HTTP and HTTPS rules and keep only SSH (port 22).** That means the only way to reach your server from the internet is through SSH -- which requires your private key. Everything else (like WhatsApp webhooks) will come through Cloudflare Tunnel later, which doesn't need any open inbound ports.

This is a security-first approach, and it's one of the best habits you can build: start locked down, open things up only when you have a reason.

## Avoiding Surprise Bills

People have AWS horror stories -- leaving something running and getting a bill for thousands of dollars. Lightsail is specifically designed to prevent this. Your instance has a flat monthly rate, and bandwidth is included up to a generous limit (the $10 plan includes 3TB of transfer, which you'll never come close to).

That said, a few things to watch:

- **Stopped instances still cost money.** If you're not using your instance, *delete* it -- don't just stop it. Stopped instances still incur charges.
- **Static IPs cost money if unattached.** A static IP attached to a running instance is free. A static IP sitting around with no instance costs $0.005/hour (~$3.60/month). Always clean up.
- **Snapshots cost $0.05/GB/month.** We'll talk about snapshots (backups) later -- they're cheap and worth it, but don't forget they exist on your bill.

The most important rule: if you decide to stop using this setup, **delete everything** -- the instance, the static IP, and any snapshots. Don't just walk away.

## What We Just Covered

- A VPS is a rented computer in a data center -- always on, always connected
- Lightsail is the simplest way to get a VPS on AWS, with predictable pricing
- The $10/month plan (1 vCPU, 2GB RAM) is the sweet spot for this project
- Static IPs are free on Lightsail and prevent your address from changing
- We lock down the firewall from day one: SSH only, no HTTP/HTTPS
- Lightsail pricing is predictable, but always clean up what you're not using

Time to actually create the thing. Head to the exercise.

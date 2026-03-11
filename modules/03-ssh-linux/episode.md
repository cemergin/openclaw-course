# Episode 3: Remote Control -- SSH and Linux Basics

## In This Episode

Your server is sitting in a data center somewhere, humming along without a keyboard or monitor attached to it. So how do you actually *control* this thing? SSH is your encrypted remote control -- and it's built on a beautifully simple idea involving a lock and a key. In this episode, you'll connect to your VPS for the first time, learn to navigate the Linux filesystem like you own the place (because you do), create a dedicated user for OpenClaw, and pick up the essential Linux commands you'll use for the rest of this course.

## Key Concepts

- **SSH key pairs** -- the public key (a lock) goes on the server, the private key (a key) stays on your machine
- **Linux filesystem layout** -- where things live: /home, /etc, /var, /root
- **Users and permissions** -- root is god mode (and that's a problem), regular users are safer
- **Package management with apt** -- how Linux installs software
- **systemd and systemctl** -- how Linux manages services that run in the background
- **File permissions** -- chmod and chown, the gatekeepers of who can read and write what

## Prerequisites

You should have a running AWS Lightsail instance with a static IP address from Module 2. You also need a terminal application on your local machine (Terminal on macOS, Windows Terminal or PowerShell on Windows, any terminal on Linux).

> **Self-check:** Can you open your terminal and tell me your Lightsail instance's IP address? If yes, you're ready.

## Builds On

- **Module 1: What Are AI Agents?** -- You understand what OpenClaw is and why we're self-hosting it
- **Module 2: Your Computer in the Sky** -- You have a running VPS with a static IP address

If you went through the **Speed Run (Module 0)**, you've already SSH'd in once -- but probably using the Lightsail browser console or a downloaded key without really understanding what happened. This module fills in that understanding.

## What's Next

In **Module 4: Containers -- Your Apps in Boxes**, we'll install Docker on the server you just learned to control. You'll use every skill from this module -- SSH, apt, systemctl, nano -- to get containers running. The non-root user you create here will be the one running OpenClaw in production.

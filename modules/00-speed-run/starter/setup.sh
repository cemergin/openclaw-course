#!/bin/bash
# =============================================================
# OpenClaw Speed Run -- Quick Setup Script
# =============================================================
# This script automates the server-side setup from the exercise.
# Run it AFTER you've SSH'd into your Lightsail instance.
#
# Usage:
#   chmod +x setup.sh
#   ./setup.sh
#
# After this script completes, you still need to:
#   1. Run `openclaw onboard` to configure your API key + Telegram bot
#   2. Run `openclaw start` to start the agent
# =============================================================

set -e  # Exit on any error

echo "=== OpenClaw Speed Run Setup ==="
echo ""

# Step 1: Update the system
echo "[1/3] Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Step 2: Install Node.js 20
echo "[2/3] Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

echo "  Node.js version: $(node --version)"
echo "  npm version: $(npm --version)"

# Step 3: Install OpenClaw
echo "[3/3] Installing OpenClaw..."
curl -fsSL https://openclaw.ai/install.sh | bash

echo ""
echo "=== Setup Complete! ==="
echo ""
echo "Next steps:"
echo "  1. Run: openclaw onboard"
echo "     (Have your Claude API key and Telegram bot token ready)"
echo ""
echo "  2. Run: openclaw start"
echo "     (Then send a message to your bot in Telegram!)"
echo ""
echo "  3. To run in background: nohup openclaw start > ~/openclaw.log 2>&1 &"
echo ""

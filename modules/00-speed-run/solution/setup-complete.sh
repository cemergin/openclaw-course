#!/bin/bash
# =============================================================
# OpenClaw Speed Run -- Complete Setup Script (Solution)
# =============================================================
# This is the "everything included" version of the setup script.
# It handles setup, background running, and auto-restart on boot.
#
# Usage:
#   chmod +x setup-complete.sh
#   ./setup-complete.sh
#
# You still need to run `openclaw onboard` interactively --
# there's no way to automate pasting your API keys (and you
# wouldn't want to put them in a script anyway).
# =============================================================

set -e

echo "=== OpenClaw Speed Run -- Complete Setup ==="
echo ""

# ----- System Update -----
echo "[1/4] Updating system packages..."
sudo apt update && sudo apt upgrade -y

# ----- Node.js -----
echo "[2/4] Installing Node.js 20..."
if command -v node &> /dev/null; then
    echo "  Node.js already installed: $(node --version)"
else
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt install -y nodejs
    echo "  Installed Node.js: $(node --version)"
fi

# ----- OpenClaw -----
echo "[3/4] Installing OpenClaw..."
if command -v openclaw &> /dev/null; then
    echo "  OpenClaw already installed: $(openclaw --version)"
else
    curl -fsSL https://openclaw.ai/install.sh | bash
    echo "  Installed OpenClaw: $(openclaw --version)"
fi

# ----- Auto-restart on boot -----
echo "[4/4] Setting up auto-restart on boot..."
# Add a crontab entry to start OpenClaw on reboot
# (This is the quick-and-dirty approach. The full course uses Docker
# with restart policies, which is much better.)
CRON_ENTRY="@reboot cd /home/ubuntu && nohup openclaw start > ~/openclaw.log 2>&1 &"
if crontab -l 2>/dev/null | grep -q "openclaw start"; then
    echo "  Auto-restart already configured."
else
    (crontab -l 2>/dev/null; echo "$CRON_ENTRY") | crontab -
    echo "  Added crontab entry for auto-restart."
fi

echo ""
echo "=== Setup Complete! ==="
echo ""
echo "What to do now:"
echo ""
echo "  1. Run the interactive setup wizard:"
echo "     $ openclaw onboard"
echo ""
echo "  2. Have these ready to paste:"
echo "     - Your Claude API key (from console.anthropic.com)"
echo "     - Your Telegram bot token (from @BotFather)"
echo ""
echo "  3. Start OpenClaw in the background:"
echo "     $ nohup openclaw start > ~/openclaw.log 2>&1 &"
echo ""
echo "  4. Open Telegram and message your bot!"
echo ""
echo "  5. To check logs later:"
echo "     $ tail -50 ~/openclaw.log"
echo ""
echo "=== What's NOT covered here (saved for the full course) ==="
echo "  - Firewall (Module 5)"
echo "  - Docker containers (Module 4)"
echo "  - Encrypted secrets (Module 6)"
echo "  - WhatsApp + Cloudflare Tunnel (Modules 7-8)"
echo "  - Monitoring and alerts (Module 10)"
echo "  - Kill switch (Module 11)"
echo ""

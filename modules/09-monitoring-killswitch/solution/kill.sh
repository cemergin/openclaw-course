#!/bin/sh
# Kill Switch Script for OpenClaw (Hybrid Stack)
# Called when the secret kill URL is triggered via Cloudflare Tunnel.
# Stops the native OpenClaw gateway and logs the event.
#
# A matching revive.sh should live alongside this file.

# Stop native OpenClaw gateway
# This uses the openclaw CLI directly -- OpenClaw runs natively, not in Docker
openclaw gateway stop

# Log the kill event with timestamp for easy searching
echo "$(date): Kill switch triggered -- OpenClaw gateway stopped" >> /var/log/killswitch.log

# --- REVIVE SCRIPT (create as revive.sh) ---
# #!/bin/sh
# openclaw gateway start
# echo "$(date): Revive triggered -- OpenClaw gateway started" >> /var/log/killswitch.log

#!/bin/bash
# status.sh -- Quick health check for OpenClaw deployment
#
# Usage: ./status.sh
# Make executable first: chmod +x status.sh

echo "=== OpenClaw Status Check ==="
echo ""

# Check OpenClaw gateway
echo "--- OpenClaw Gateway ---"
openclaw gateway status
echo ""

# Run diagnostics
echo "--- OpenClaw Doctor ---"
openclaw doctor
echo ""

# Check support services
echo "--- Support Services (Docker) ---"
cd ~/openclaw
docker compose ps
echo ""

# Check resource usage
echo "--- Resource Usage ---"
echo "Memory:"
free -h | head -2
echo ""
echo "Disk:"
df -h / | tail -1
echo ""

# Check gateway port
echo "--- Gateway Port Check ---"
curl -sf http://127.0.0.1:18789/ > /dev/null && echo "Port 18789: RESPONDING" || echo "Port 18789: NOT RESPONDING"
echo ""

# Check OpenClaw version
echo "--- Versions ---"
echo "OpenClaw: $(openclaw --version)"
echo "Node.js:  $(node --version)"
echo "Docker:   $(docker --version)"
echo ""

echo "=== Check Complete ==="

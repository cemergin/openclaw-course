#!/bin/bash
# status.sh -- Quick health check for OpenClaw deployment
#
# Usage: ./status.sh
# Make executable first: chmod +x status.sh

echo "=== OpenClaw Status Check ==="
echo ""

# TODO: Check OpenClaw gateway status
# Hint: openclaw gateway status

echo "--- OpenClaw Gateway ---"
echo "TODO: Add gateway status check here"
echo ""

# TODO: Run OpenClaw doctor
# Hint: openclaw doctor

echo "--- OpenClaw Doctor ---"
echo "TODO: Add doctor check here"
echo ""

# TODO: Check support services
# Hint: cd ~/openclaw && docker compose ps

echo "--- Support Services ---"
echo "TODO: Add docker compose ps here"
echo ""

# TODO: Check resource usage
# Hint: free -h and df -h /

echo "--- Resource Usage ---"
echo "TODO: Add memory and disk checks here"
echo ""

# TODO: Check gateway port
# Hint: curl -sf http://127.0.0.1:18789/

echo "--- Gateway Port Check ---"
echo "TODO: Add port check here"
echo ""

echo "=== Check Complete ==="

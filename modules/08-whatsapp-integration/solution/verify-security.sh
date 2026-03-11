#!/bin/bash
# Security Verification Script for WhatsApp Integration
#
# Run this after completing the exercise and challenge to verify
# all security layers are working correctly.
#
# Usage: bash verify-security.sh

echo "=== WhatsApp Integration Security Check ==="
echo ""

# 1. Check that secrets exist with correct permissions
echo "--- Checking secret file permissions ---"
for secret in whatsapp_access_token whatsapp_phone_number_id whatsapp_business_account_id whatsapp_app_secret whatsapp_verify_token; do
    file="/home/openclaw/secrets/$secret"
    if [ -f "$file" ]; then
        perms=$(stat -c '%a' "$file" 2>/dev/null || stat -f '%Lp' "$file" 2>/dev/null)
        if [ "$perms" = "600" ]; then
            echo "  [OK] $secret -- permissions 600"
        else
            echo "  [!!] $secret -- permissions $perms (should be 600)"
        fi
    else
        echo "  [MISSING] $secret"
    fi
done

echo ""

# 2. Check that secrets are NOT in docker environment
echo "--- Checking secrets are NOT in Docker environment ---"
env_check=$(docker inspect openclaw 2>/dev/null | grep -i "whatsapp" | grep -v "run/secrets" || true)
if [ -z "$env_check" ]; then
    echo "  [OK] No WhatsApp credentials found in Docker environment"
else
    echo "  [!!] Found WhatsApp credentials in Docker environment:"
    echo "  $env_check"
fi

echo ""

# 3. Check that OpenClaw is running
echo "--- Checking services ---"
if docker compose ps --format json 2>/dev/null | grep -q "openclaw"; then
    echo "  [OK] OpenClaw is running"
else
    echo "  [!!] OpenClaw is not running"
fi

if docker compose ps --format json 2>/dev/null | grep -q "cloudflared"; then
    echo "  [OK] Cloudflared is running"
else
    echo "  [!!] Cloudflared is not running"
fi

echo ""

# 4. Test that direct port access is blocked
echo "--- Checking direct port access is blocked ---"
direct_result=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 http://localhost:3000/webhook/whatsapp 2>/dev/null || echo "timeout")
echo "  localhost:3000 returned: $direct_result (this is expected -- only the tunnel should route external traffic)"

echo ""

# 5. Test signature verification by sending an unsigned request
echo "--- Testing signature verification (sending unsigned request) ---"
unsigned_result=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:3000/webhook/whatsapp \
    -H "Content-Type: application/json" \
    -d '{"object":"whatsapp_business_account","entry":[]}' 2>/dev/null || echo "error")
echo "  Unsigned POST returned: $unsigned_result"
if [ "$unsigned_result" = "401" ] || [ "$unsigned_result" = "403" ]; then
    echo "  [OK] Unsigned requests are rejected"
elif [ "$unsigned_result" = "200" ]; then
    echo "  [!!] Unsigned request was accepted -- signature verification may not be working"
else
    echo "  [??] Unexpected status -- check OpenClaw logs for details"
fi

echo ""
echo "=== Check complete ==="
echo ""
echo "For detailed webhook logs, run:"
echo "  docker compose logs --tail=20 openclaw"

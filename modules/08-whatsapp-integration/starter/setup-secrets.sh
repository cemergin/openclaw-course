#!/bin/bash
# WhatsApp Secrets Setup Script
# Run this on your VPS to create the secret files for WhatsApp integration.
#
# Usage: bash setup-secrets.sh
#
# This script will prompt you for each credential and store it
# as a Docker Secret file with proper permissions.

SECRETS_DIR="/home/openclaw/secrets"

echo "=== WhatsApp Secrets Setup ==="
echo ""
echo "This script will create secret files for your WhatsApp integration."
echo "Have your Meta developer dashboard open -- you'll need values from it."
echo ""

# Create secrets directory if needed
sudo mkdir -p "$SECRETS_DIR"

# Function to safely write a secret
write_secret() {
    local name=$1
    local description=$2

    echo ""
    echo "--- $description ---"
    read -rp "Paste value (or press Enter to skip): " value

    if [ -z "$value" ]; then
        echo "Skipped $name"
        return
    fi

    # Write without trailing newline
    echo -n "$value" | sudo tee "$SECRETS_DIR/$name" > /dev/null
    sudo chmod 600 "$SECRETS_DIR/$name"
    sudo chown openclaw:openclaw "$SECRETS_DIR/$name"
    echo "Saved $name"
}

# TODO: Run this script and fill in each value from the Meta dashboard

write_secret "whatsapp_access_token" \
    "Access Token (from WhatsApp > Getting Started)"

write_secret "whatsapp_phone_number_id" \
    "Phone Number ID (from WhatsApp > Getting Started)"

write_secret "whatsapp_business_account_id" \
    "Business Account ID (from WhatsApp > Getting Started)"

write_secret "whatsapp_app_secret" \
    "App Secret (from App Settings > Basic)"

write_secret "whatsapp_verify_token" \
    "Webhook Verify Token (the random string you generated)"

echo ""
echo "=== Done ==="
echo ""
echo "Verify your secrets:"
echo "  ls -la $SECRETS_DIR/whatsapp_*"
echo ""
echo "Next steps:"
echo "  1. Add the secrets to your docker-compose.yml (see docker-compose.whatsapp.yml)"
echo "  2. Configure the webhook in Meta's developer portal"
echo "  3. Restart OpenClaw: docker compose restart openclaw"

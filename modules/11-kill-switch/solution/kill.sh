#!/bin/sh
# Kill Switch Script for OpenClaw
# Called when the secret kill URL is triggered via Cloudflare Tunnel.
# Stops the OpenClaw container via Docker socket and logs the event.

# Stop the OpenClaw container
# Uses the container name defined in docker-compose.yml
docker stop openclaw

# Log the kill event with ISO timestamp for easy searching
echo "$(date): Kill switch triggered" >> /var/log/killswitch.log

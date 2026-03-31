#!/bin/bash
# OpenClaw Health Check Script (Hybrid Stack)
# Run manually or via cron to monitor server health and service status.
# Checks both native OpenClaw and Docker support containers.
#
# Usage:
#   chmod +x healthcheck.sh
#   ./healthcheck.sh
#
# Cron (every 5 minutes):
#   */5 * * * * /home/openclaw/healthcheck.sh >> /var/log/openclaw-health.log 2>&1

# =============================================================================
# THRESHOLDS
# TODO: Set your alert thresholds (as percentages).
# On a $5/mo 1GB VPS, memory is your tightest constraint.
# Start with 80 for CPU/disk, 85 for memory.
# =============================================================================
CPU_THRESHOLD=
MEM_THRESHOLD=
DISK_THRESHOLD=

# =============================================================================
# READ CURRENT USAGE
# TODO: Fill in the commands to read current CPU, memory, and disk usage.
# Each should produce an integer percentage (e.g., 42 for 42%).
#
# Hints:
#   CPU:  top -bn1 gives a snapshot. Look for the "Cpu(s)" line.
#   MEM:  free shows memory. Calculate used/total * 100.
#   DISK: df / shows disk usage. The 5th column is the percentage.
# =============================================================================
CPU_USAGE=    # TODO: command to get CPU usage as integer percentage
MEM_USAGE=    # TODO: command to get memory usage as integer percentage
DISK_USAGE=   # TODO: command to get disk usage as integer percentage

# =============================================================================
# SERVICE CHECKS
# TODO: Check if native OpenClaw is running.
# Unlike the Docker-only approach, we check the native process directly.
#
# Hint: openclaw gateway status tells you if the gateway is running.
# If it's NOT running, print an alert and restart it.
#
# Also check Docker support containers (cloudflared, uptime-kuma).
# Hint: docker ps | grep -q <container-name>
# =============================================================================

# TODO: Check native OpenClaw
# if ! openclaw gateway status | grep -q "running"; then
#     echo "ALERT: OpenClaw is DOWN -- restarting..."
#     openclaw gateway start
# fi

# TODO: Check Docker support containers
# if ! docker ps | grep -q cloudflared; then
#     echo "ALERT: cloudflared is DOWN -- restarting..."
#     cd /home/openclaw/openclaw-deploy && docker compose up -d cloudflared
# fi

# =============================================================================
# THRESHOLD CHECKS
# These are done for you -- they compare each reading against its threshold
# and print a warning if the threshold is exceeded.
# =============================================================================
if [ "$CPU_USAGE" -gt "$CPU_THRESHOLD" ]; then
    echo "WARNING: CPU at ${CPU_USAGE}% (threshold: ${CPU_THRESHOLD}%)"
fi

if [ "$MEM_USAGE" -gt "$MEM_THRESHOLD" ]; then
    echo "WARNING: Memory at ${MEM_USAGE}% (threshold: ${MEM_THRESHOLD}%)"
fi

if [ "$DISK_USAGE" -gt "$DISK_THRESHOLD" ]; then
    echo "WARNING: Disk at ${DISK_USAGE}% (threshold: ${DISK_THRESHOLD}%)"
fi

# =============================================================================
# LOG LINE
# TODO: Print a summary line with the current date and all readings.
# Format: "Wed Mar 30 14:30:00 UTC 2026: CPU=3% MEM=62% DISK=41% -- OK"
#
# Hint: $(date) gives the current timestamp.
# =============================================================================

# TODO: echo a summary line

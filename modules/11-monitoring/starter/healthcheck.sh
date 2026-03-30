#!/bin/bash
# OpenClaw Health Check Script
# Run manually or via cron to monitor server health and service status.
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
# Start with 80 for all three -- you can tune them later based on actual usage.
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
# SERVICE CHECK
# TODO: Check if the OpenClaw container is running.
# If it's NOT running, print an alert and restart it.
#
# Hint: docker ps lists running containers. Use grep -q to check quietly.
# The restart command is: cd /home/openclaw/openclaw-stack && docker compose restart openclaw
# =============================================================================

# TODO: Write an if statement that checks if "openclaw" appears in docker ps output.
# If it doesn't, echo an alert message and restart the service.

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
# Format: "Wed Mar 11 14:30:00 UTC 2026: CPU=3% MEM=62% DISK=41% -- OK"
#
# Hint: $(date) gives the current timestamp.
# =============================================================================

# TODO: echo a summary line

# =============================================================================
# OPTIONAL: External dead-man's switch
# If you set up Healthchecks.io, uncomment and add your ping URL:
# =============================================================================
# curl -fsS -m 10 --retry 5 https://hc-ping.com/YOUR_UUID > /dev/null

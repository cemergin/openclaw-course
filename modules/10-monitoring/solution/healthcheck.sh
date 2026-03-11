#!/bin/bash
# OpenClaw Health Check Script
# Monitors CPU, memory, disk, and service status.
# Automatically restarts OpenClaw if it crashes.
# Logs results for historical review.
#
# Usage:
#   chmod +x healthcheck.sh
#   ./healthcheck.sh
#
# Cron (every 5 minutes):
#   */5 * * * * /home/openclaw/healthcheck.sh >> /var/log/openclaw-health.log 2>&1

# =============================================================================
# THRESHOLDS
# 80% is a good starting point. Tune based on your server's normal usage.
# See Challenge 3 for guidance on choosing the right values.
# =============================================================================
CPU_THRESHOLD=80
MEM_THRESHOLD=80
DISK_THRESHOLD=80

# =============================================================================
# READ CURRENT USAGE
# Each command extracts a single integer percentage from system tools.
# =============================================================================

# top -bn1: run top in batch mode for one iteration
# grep "Cpu(s)": find the CPU summary line
# awk '{print int($2)}': extract the user CPU percentage as an integer
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print int($2)}')

# free: show memory stats
# awk '/Mem/': find the line starting with "Mem"
# $3/$2*100: used memory / total memory * 100 = percentage
MEM_USAGE=$(free | awk '/Mem/{printf("%d"), $3/$2*100}')

# df /: show disk usage for the root partition
# NR==2: second line (skip the header)
# int($5): the "Use%" column, converted to integer (strips the % sign)
DISK_USAGE=$(df / | awk 'NR==2{print int($5)}')

# =============================================================================
# SERVICE CHECK
# Verify OpenClaw is running. If not, log an alert and restart it.
# The docker compose restart command brings the container back up.
# =============================================================================
if ! docker ps | grep -q openclaw; then
    echo "ALERT: OpenClaw is DOWN -- restarting..."
    cd /home/openclaw/openclaw-stack && docker compose restart openclaw
fi

# =============================================================================
# THRESHOLD CHECKS
# Only print warnings when thresholds are exceeded.
# This keeps the log clean during normal operation.
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
# Always print a summary so the log shows continuous operation.
# The "OK" at the end makes it easy to grep for healthy vs problem entries.
# =============================================================================
echo "$(date): CPU=${CPU_USAGE}% MEM=${MEM_USAGE}% DISK=${DISK_USAGE}% -- OK"

# =============================================================================
# OPTIONAL: External dead-man's switch (Healthchecks.io)
# Uncomment and replace YOUR_UUID with your actual check UUID.
# If this ping stops arriving, Healthchecks.io emails you.
#
# Flags:
#   -f    fail silently on HTTP errors
#   -sS   silent mode but show errors
#   -m 10 timeout after 10 seconds
#   --retry 5  retry up to 5 times on failure
# =============================================================================
# curl -fsS -m 10 --retry 5 https://hc-ping.com/YOUR_UUID > /dev/null

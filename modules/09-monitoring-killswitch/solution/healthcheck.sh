#!/bin/bash
# OpenClaw Health Check Script (Hybrid Stack)
# Monitors CPU, memory, disk, native OpenClaw, and Docker support containers.
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
# On a $5/mo 1GB VPS, memory is your tightest constraint.
# 80% for CPU/disk, 85% for memory.
# =============================================================================
CPU_THRESHOLD=80
MEM_THRESHOLD=85
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
# SERVICE CHECKS
# Check native OpenClaw and Docker support containers.
# =============================================================================

# Check native OpenClaw gateway
if ! openclaw gateway status 2>/dev/null | grep -q "running"; then
    echo "ALERT: OpenClaw is DOWN -- restarting..."
    openclaw gateway start
fi

# Check Docker support containers
if ! docker ps | grep -q cloudflared; then
    echo "ALERT: cloudflared is DOWN -- restarting..."
    cd /home/openclaw/openclaw-deploy && docker compose up -d cloudflared
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

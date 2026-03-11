#!/bin/sh
# entrypoint-wrapper.sh
# Converts Docker secrets (files in /run/secrets/) to environment variables.
#
# Why this exists:
#   Docker file-based secrets mount at /run/secrets/<name>, but many apps
#   expect configuration via environment variables (e.g., ANTHROPIC_API_KEY).
#   This script bridges the gap: it reads each secret file, exports it as
#   an uppercase environment variable, then hands off to the real application.
#
# Security note:
#   The secrets only enter the environment of this process and its children.
#   They do NOT appear in docker inspect, Docker's metadata, or the container
#   config. They exist only in the running process's environment.
#
# Example:
#   /run/secrets/anthropic_api_key --> ANTHROPIC_API_KEY=sk-ant-api03-...

for secret_file in /run/secrets/*; do
  # Skip if not a regular file (could be a directory or glob that matched nothing)
  if [ -f "$secret_file" ]; then
    # Extract filename: /run/secrets/anthropic_api_key --> anthropic_api_key
    # Convert to uppercase: anthropic_api_key --> ANTHROPIC_API_KEY
    var_name=$(basename "$secret_file" | tr '[:lower:]' '[:upper:]')

    # Read the file contents and export as an environment variable
    export "$var_name"="$(cat "$secret_file")"
  fi
done

# exec replaces this shell process with the actual command.
# This ensures:
#   1. Signals (SIGTERM, SIGINT) reach the app directly
#   2. The app becomes PID 1, which Docker expects
#   3. No extra shell process lingers in memory
exec "$@"

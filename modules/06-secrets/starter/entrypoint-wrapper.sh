#!/bin/sh
# entrypoint-wrapper.sh
# Converts Docker secrets (files in /run/secrets/) to environment variables.
#
# How it works:
#   1. Loop through every file in /run/secrets/
#   2. Convert the filename to an uppercase environment variable name
#   3. Read the file contents and export them as the variable's value
#   4. Hand off to the real application command
#
# Example:
#   /run/secrets/anthropic_api_key --> ANTHROPIC_API_KEY=<file contents>

# TODO: Write a for loop that iterates over files in /run/secrets/
# For each file:
#   - Check that it's actually a file (not a directory)
#   - Extract the filename (hint: basename)
#   - Convert to uppercase (hint: tr '[:lower:]' '[:upper:]')
#   - Export the variable with the file's contents (hint: cat)



# TODO: Replace this line with the exec command that hands off to the real entrypoint.
# The command should use exec with "$@" to pass through whatever arguments
# Docker gives us (the CMD from docker-compose.yml).
echo "ERROR: entrypoint-wrapper.sh is not fully implemented yet."
exit 1

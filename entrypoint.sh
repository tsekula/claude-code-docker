#!/bin/bash
set -e

# Write ANTHROPIC_API_KEY to secrets file for all tmux sessions
if [ -n "${ANTHROPIC_API_KEY}" ]; then
    echo "export ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}" > /home/claude/.env_secrets
    chmod 600 /home/claude/.env_secrets
    chown claude:claude /home/claude/.env_secrets
fi

# Ensure claude owns their home directory
chown -R claude:claude /home/claude

# Keep container alive; access via docker exec
exec sleep infinity

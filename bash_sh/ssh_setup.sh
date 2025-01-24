#!/bin/bash

# Start ssh-agent if not already running
if [ -z "$SSH_AUTH_SOCK" ]; then
    if [ -r "$HOME/.ssh/agent.sock" ]; then
        export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"
    else
        eval "$(ssh-agent -s)"
        ln -sf "$SSH_AUTH_SOCK" "$HOME/.ssh/agent.sock"
    fi
fi

# Add SSH keys from ~/.ssh folder
for key in $(find ~/.ssh -type f -name "id_rsa*" -not -name "*.pub"); do
    ssh-add "$key" 2>/dev/null
done

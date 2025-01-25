#!/bin/bash

# Ensure .ssh directory exists with proper permissions
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Start ssh-agent if not already running
if [ -z "$SSH_AUTH_SOCK" ]; then
  # Try to find existing agent
  if [ -S ~/.ssh/agent.sock ] && SSH_AUTH_SOCK=~/.ssh/agent.sock ssh-add -l >/dev/null 2>&1; then
    export SSH_AUTH_SOCK=~/.ssh/agent.sock
    echo "Reusing existing ssh-agent"
  else
    echo "Starting new ssh-agent"
		rm -f ~/.ssh/agent.sock
    eval "$(ssh-agent -s -a ~/.ssh/agent.sock)" >/dev/null
    export SSH_AUTH_SOCK=~/.ssh/agent.sock
  fi
fi

# Add SSH keys with proper permissions
for key in $(find ~/.ssh -type f \( -name "id_rsa*" -o -name "id_ed25519*" \) -not -name "*.pub"); do
  if [ -f "$key" ]; then
    # Fix permissions first
    chmod 600 "$key" || { echo "Error: Failed to set permissions for $key"; continue; }
    
    # Add key if not already present
    if ! ssh-add -l | grep -qF "$(ssh-keygen -lf "$key" | awk '{print $2}')"; then
      echo "Adding SSH key: $(basename "$key")"
      ssh-add "$key"
    fi
  fi
done

echo Sourced ssh_setup.sh

#!/usr/bin/env bash
# Detect OS and export OS_TYPE + DOTFILES

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DOTFILES

if [ -f /etc/NIXOS ]; then
  OS_TYPE=nixos
elif [[ "$(uname)" == "Darwin" ]]; then
  OS_TYPE=darwin
else
  OS_TYPE=linux
fi
export OS_TYPE

echo "Detected OS: $OS_TYPE"


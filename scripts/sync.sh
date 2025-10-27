#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
fi

# Repo root
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES

# Detect OS
source "$DOTFILES/link/detect-os.sh"

# Re-run installs & links
# source "$DOTFILES/setup/install-packages.sh"
source "$DOTFILES/setup/link-dotfiles.sh"

echo "Sync complete."


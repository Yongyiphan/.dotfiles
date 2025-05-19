#!/usr/bin/env bash
set -euo pipefail

# Repo root
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES

# Detect OS
source "$DOTFILES/setup/detect-os.sh"

# Update repo
echo "Pulling latest changes..."
git -C "$DOTFILES" pull --ff-only

# Re-run installs & links
source "$DOTFILES/setup/install-packages.sh"
source "$DOTFILES/setup/link-dotfiles.sh"

echo "Sync complete."


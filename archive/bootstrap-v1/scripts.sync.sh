#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
fi

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES

source "$DOTFILES/link/detect-os.sh"

source "$DOTFILES/setup/link-dotfiles.sh"

echo "Sync complete."

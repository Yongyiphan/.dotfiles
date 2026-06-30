#!/usr/bin/env bash
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
fi

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES

source "$DOTFILES/lib/detect-os.sh"

bash "$DOTFILES/setup/brew-setup.sh"
bash "$DOTFILES/setup/install-packages.sh"
bash "$DOTFILES/setup/link-dotfiles.sh"

echo
echo "Bootstrap complete! Start a new shell or run 'source ~/.profile'."

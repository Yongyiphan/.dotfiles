#!/usr/bin/env bash
set -euo pipefail

# 1) locate repo
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES

# 2) detect OS
source "$DOTFILES/setup/detect-os.sh"

# 3) install Homebrew & Brewfile (macOS/WSL)
bash "$DOTFILES/setup/brew-setup.sh"

# 4) install distro packages (APT/NixOS)
bash "$DOTFILES/setup/install-packages.sh"

# 5) symlink all your dotfiles
bash "$DOTFILES/setup/link-dotfiles.sh"

echo
echo "✅ bootstrap complete! Start a new shell or run 'source ~/.profile'."


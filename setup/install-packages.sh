#!/usr/bin/env bash
set -euo pipefail

echo "Installing packages for $OS_TYPE"

case "$OS_TYPE" in

  nixos)
    # NixOS
    nix-env -iA nixpkgs.git nixpkgs.zsh nixpkgs.neovim
    if command -v home-manager &>/dev/null; then
      echo "Applying Home Manager configuration"
      home-manager switch --flake "$DOTFILES#$(whoami)" || true
    fi
    ;;

  darwin)
    # macOS
    if ! command -v brew &>/dev/null; then
      echo "Installing Homebrew"
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      eval "$(brew shellenv)"
    fi
    if [ -f "$DOTFILES/Brewfile" ]; then
      brew bundle --file="$DOTFILES/Brewfile"
    fi
    ;;

  linux)
    # Debian/Ubuntu
    if [ -f /etc/debian_version ] && [ -f "$DOTFILES/apt-packages.txt" ]; then
      PKGS=$(grep -vE '^\s*(#|$)' "$DOTFILES/apt-packages.txt" | xargs || true)
      if [ -n "$PKGS" ]; then
        echo "Updating apt and installing packages: $PKGS"
        sudo apt update
        sudo apt install -y $PKGS
      fi
    fi

    # Homebrew on Linux/WSL (optional)
    if [ -f "$DOTFILES/Brewfile" ]; then
      if ! command -v brew &>/dev/null; then
        echo "Installing Homebrew"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(brew shellenv)"
      fi
      brew bundle --file="$DOTFILES/Brewfile"
    fi
    ;;

  *)
    echo "Unknown OS_TYPE=$OS_TYPE, skipping package installation"
    ;;
esac

echo "Package installation complete"


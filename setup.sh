#!/bin/bash

# Variables
DOTFILES_DIR=~/.dotfiles
BASH_SH_DIR="$DOTFILES_DIR/bash_sh"

# Symlink dotfiles
"$BASH_SH_DIR/symlink.sh"

# Setup Homebrew
"$BASH_SH_DIR/installation.sh"

# Restore apt packages
"$BASH_SH_DIR/apt_packages.sh" restore

# Restore brew packages
"$BASH_SH_DIR/brew_packages.sh" restore

echo "Dotfiles setup complete!"

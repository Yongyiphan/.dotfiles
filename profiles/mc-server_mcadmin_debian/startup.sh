#!/usr/bin/bash

echo "$DOTFILES_PROFILE" running custom
export EDITOR="$HOME/.local/bin/nvim"
export VISUAL="$HOME/.local/bin/nvim"

snvim() {
  sudo -E /home/mcadmin/.local/bin/nvim "$@"
}

alias svm=snvim

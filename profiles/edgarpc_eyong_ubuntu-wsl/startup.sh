#!/usr/bin/bash

echo "$DOTFILES_PROFILE" running custom
export EDITOR=/home/linuxbrew/.linuxbrew/bin/nvim
export VISUAL=/home/linuxbrew/.linuxbrew/bin/nvim

snvim() {
  sudo -E /home/linuxbrew/.linuxbrew/bin/nvim "$@"
}

alias svm=snvim


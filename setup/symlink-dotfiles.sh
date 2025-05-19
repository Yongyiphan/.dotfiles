#!/usr/bin/env bash
set -euo pipefail

echo "Cleaning up broken symlinks"
find "$HOME" \( -path "$HOME/.config/*" -o -path "$HOME/.*" \) -type l | while read -r L; do
  T=$(readlink "$L")
  [[ "$T" != /* ]] && T="$(dirname "$L")/$T"
  if [[ "$T" == "$DOTFILES/home"* && ! -e "$T" ]]; then
    rm "$L"
    echo "Removed stale symlink: $L"
  fi
done

BACKUP="$HOME/.dotfiles_backup/$(date +%Y%m%dT%H%M%S)"
mkdir -p "$BACKUP"

echo "Linking files from home/ to $HOME"
find "$DOTFILES/home" -type f ! -path "$DOTFILES/home/config/*" | while read -r SRC; do
  REL="${SRC#$DOTFILES/home/}"
  DST="$HOME/.$REL"
  mkdir -p "$(dirname "$DST")"
  if [ -e "$DST" ] && [ ! -L "$DST" ]; then
    mv "$DST" "$BACKUP/$REL"
    echo "Backed up $DST to $BACKUP/$REL"
  fi
  ln -sf "$SRC" "$DST"
  echo "Linked $DST to $SRC"
done

echo "Linking files from home/config/ to $HOME/.config"
find "$DOTFILES/home/config" -type f | while read -r SRC; do
  REL="${SRC#$DOTFILES/home/config/}"
  DST="$HOME/.config/$REL"
  mkdir -p "$(dirname "$DST")"
  if [ -e "$DST" ] && [ ! -L "$DST" ]; then
    mv "$DST" "$BACKUP/config/$REL"
    echo "Backed up $DST to $BACKUP/config/$REL"
  fi
  ln -sf "$SRC" "$DST"
  echo "Linked $DST to $SRC"
done

if [ -d "$DOTFILES/bin" ]; then
  echo "Linking executables from bin/ to ~/.local/bin"
  mkdir -p "$HOME/.local/bin"
  find "$DOTFILES/bin" -type f | while read -r SRC; do
    DST="$HOME/.local/bin/$(basename "$SRC")"
    ln -sf "$SRC" "$DST"
    echo "Linked $DST to $SRC"
  done
  PROFILE="$HOME/.profile"
  ENTRY='export PATH="$HOME/.local/bin:$PATH"'
  if ! grep -qxF "$ENTRY" "$PROFILE"; then
    echo "$ENTRY" >> "$PROFILE"
    echo "Added ~/.local/bin to PATH in $PROFILE"
  fi
fi

if [ "$OS_TYPE" = "nixos" ]; then
  echo "Linking NixOS configuration files"
  sudo mkdir -p /etc/nixos
  sudo chown root:root /etc/nixos
  sudo ln -sf "$DOTFILES/nixos/configuration.nix" /etc/nixos/configuration.nix
  if [ -f "$DOTFILES/nixos/hardware-configuration.nix" ]; then
    sudo ln -sf "$DOTFILES/nixos/hardware-configuration.nix" /etc/nixos/hardware-configuration.nix
  fi
  if [ -f "$DOTFILES/nixos/flake.nix" ]; then
    sudo ln -sf "$DOTFILES/nixos/flake.nix" /etc/nixos/flake.nix
  fi
  echo "NixOS config linked; run 'sudo nixos-rebuild switch'"
fi

echo "Dotfiles linking complete; backups located in $BACKUP"


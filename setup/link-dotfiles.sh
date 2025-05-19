#!/usr/bin/env bash
# Quietly link dotfiles, ignoring individual link errors
# Usage: link-dotfiles.sh [-q|--quiet]

set -u -o pipefail

# parse options
QUIET=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    -q|--quiet)
      QUIET=1; shift;;
    *)
      echo "Unknown option: $1" >&2; exit 1;;
  esac
done

# helper to log messages
log() {
  if [ "$QUIET" -eq 0 ]; then
    echo "$@"
  fi
}

# turn off immediate exit on error for symlink operations
set +e

# Cleanup stale symlinks
log "Cleaning up broken symlinks"
find "$HOME" \( -path "$HOME/.config/*" -o -path "$HOME/.*" \) -type l | while read -r L; do
  TARGET=$(readlink "$L")
  [[ "$TARGET" != /* ]] && TARGET="$(dirname "$L")/$TARGET"
  if [[ "$TARGET" == "$DOTFILES/home"* && ! -e "$TARGET" ]]; then
    rm "$L"
    log "Removed stale symlink: $L"
  fi
done

# Prepare backup directory
BACKUP="$HOME/.dotfiles_backup/$(date +%Y%m%dT%H%M%S)"
mkdir -p "$BACKUP"

# Link home/ → ~/.<file>
log "Linking user dotfiles"
find "$DOTFILES/home" -maxdepth 2 -type f ! -path "$DOTFILES/home/config/*" | while read -r SRC; do
  REL=${SRC#$DOTFILES/home/}
  DST="$HOME/.$REL"
  mkdir -p "$(dirname "$DST")"
  if [ -e "$DST" ] && [ ! -L "$DST" ]; then
    mv "$DST" "$BACKUP/$REL"; log "Backed up $DST"
  fi
  ln -sf "$SRC" "$DST" || log "Warning: failed to link $DST"
done

# Link home/config → ~/.config
log "Linking XDG config files"
find "$DOTFILES/home/config" -type f | while read -r SRC; do
  REL=${SRC#$DOTFILES/home/config/}
  DST="$HOME/.config/$REL"
  mkdir -p "$(dirname "$DST")"
  if [ -e "$DST" ] && [ ! -L "$DST" ]; then
    mv "$DST" "$BACKUP/config/$REL"; log "Backed up $DST"
  fi
  ln -sf "$SRC" "$DST" || log "Warning: failed to link $DST"
done

# Link bin/ → ~/.local/bin
if [ -d "$DOTFILES/bin" ]; then
  log "Linking executables"
  mkdir -p "$HOME/.local/bin"
  find "$DOTFILES/bin" -type f | while read -r SRC; do
    DST="$HOME/.local/bin/$(basename "$SRC")"
    ln -sf "$SRC" "$DST" || log "Warning: failed to link $DST"
  done
  PROFILE="$HOME/.profile"
  ENTRY='export PATH="$HOME/.local/bin:$PATH"'
  grep -qxF "$ENTRY" "$PROFILE" || { echo "$ENTRY" >> "$PROFILE"; log "Updated PATH"; }
fi

# Link NixOS configs
if [ "${OS_TYPE:-}" = "nixos" ]; then
  log "Linking NixOS configs"
  sudo mkdir -p /etc/nixos; sudo chown root:root /etc/nixos
  sudo ln -sf "$DOTFILES/nixos/configuration.nix" /etc/nixos/configuration.nix || log "Warning: failed to link configuration.nix"
  [ -f "$DOTFILES/nixos/hardware-configuration.nix" ] \
    && sudo ln -sf "$DOTFILES/nixos/hardware-configuration.nix" /etc/nixos/hardware-configuration.nix || log "Warning: failed to link hardware-configuration.nix"
  [ -f "$DOTFILES/nixos/flake.nix" ] \
    && sudo ln -sf "$DOTFILES/nixos/flake.nix" /etc/nixos/flake.nix || log "Warning: failed to link flake.nix"
  log "NixOS configs linked (run 'sudo nixos-rebuild switch')"
fi

# restore immediate exit on error
set -e

log "Dotfiles linking complete; backups in $BACKUP"


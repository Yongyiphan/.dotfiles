#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
fi


# 1) Point this at your repo’s home/ directory
DOTFILES_HOME="${DOTFILES_HOME:-$HOME/.dotfiles/home}"

# 2) Prepare a backup for any real files we’ll replace
BACKUP="$HOME/.dotfiles_backup/$(date +%Y%m%dT%H%M%S)"
mkdir -p "$BACKUP"

# 3) Remove any stale symlinks under $HOME (only those pointing into DOTFILES_HOME)
find "$HOME" -maxdepth 2 -type l | while read -r L; do
  TARGET=$(readlink "$L")
  if [[ "$TARGET" == "$DOTFILES_HOME"* ]]; then
    echo "Removing stale symlink $L → $TARGET"
    rm "$L"
  fi
done

# 4) Link all files under DOTFILES_HOME except config/ and bin/
find "$DOTFILES_HOME" -maxdepth 2 -type f \
  ! -path "$DOTFILES_HOME/config/*" \
  ! -path "$DOTFILES_HOME/bin/*" | while read -r SRC; do

  # basename gives you “.bashrc” or “.profile” etc.
  NAME=$(basename "$SRC")
  DST="$HOME/$NAME"

  # If it’s a real file (not symlink), back it up
  if [ -e "$DST" ] && [ ! -L "$DST" ]; then
    echo "Backing up $DST → $BACKUP/$NAME"
    mv "$DST" "$BACKUP/$NAME"
  fi

  # Create the symlink
  ln -sfn "$SRC" "$DST"
  echo "Linked $DST → $SRC"
done

# 5) Link your entire XDG config tree in one shot
rm -rf "$HOME/.config"
ln -sfn "$DOTFILES_HOME/config" "$HOME/.config"
echo "Linked ~/.config → $DOTFILES_HOME/config"

# 6) Link any executables under bin/ into ~/.local/bin
if [ -d "$DOTFILES_HOME/bin" ]; then
  mkdir -p "$HOME/.local/bin"
  # remove old bin symlinks pointing into DOTFILES_HOME
  find "$HOME/.local/bin" -maxdepth 1 -type l | while read -r L; do
    if [[ "$(readlink "$L")" == "$DOTFILES_HOME/bin"* ]]; then
      rm "$L"
    fi
  done
  find "$DOTFILES_HOME/bin" -maxdepth 1 -type f | while read -r SRC; do
    DST="$HOME/.local/bin/$(basename "$SRC")"
    ln -sfn "$SRC" "$DST"
    echo "Linked $DST → $SRC"
  done
fi

# 6) Link TMUX
ln -s ~/.config/tmux/.tmux.conf ~/.tmux.conf
echo "Done! Any overwritten files are backed up under $BACKUP."

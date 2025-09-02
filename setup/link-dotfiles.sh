#!/usr/bin/env bash

# Only enable strict mode when executed directly (not when sourced)
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
fi

# 1) Point this at your repo’s home/ directory
DOTFILES_HOME="${DOTFILES_HOME:-$HOME/.dotfiles/home}"
DOTFILES="${DOTFILES:-$HOME/.dotfiles}"

# ---- backup helpers ----------------------------------------------------------
BACKUP_ROOT="${BACKUP_ROOT:-$HOME/.dotfiles_backup}"
HOSTTAG="${HOSTTAG:-$(hostname -s 2>/dev/null || hostname)}"
RUN_ID="${RUN_ID:-$(date +%Y%m%dT%H%M%S)}"
BACKUP="${BACKUP:-$BACKUP_ROOT/$HOSTTAG/$RUN_ID}"
MANIFEST="$BACKUP/.manifest.tsv"
mkdir -p "$BACKUP"

# Back up a real file/dir at $1, preserving relative path under $HOME, and log it
backup_if_real() {
  local dst="$1" rel
  [ -e "$dst" ] && [ ! -L "$dst" ] || return 0
  rel="${dst#$HOME/}"
  mkdir -p "$BACKUP/$(dirname "$rel")"
  mv "$dst" "$BACKUP/$rel"
  printf '%s\t%s\n' "$rel" "moved $(date -Is)" >>"$MANIFEST"
  echo "Backed up ~/$rel → $BACKUP/$rel"
}

# Keep only the last N backups per host (default 5)
prune_old_backups() {
  local keep="${DOTFILES_BACKUP_KEEP:-5}"
  mapfile -t runs < <(ls -1dt "$BACKUP_ROOT/$HOSTTAG"/* 2>/dev/null || true)
  ((${#runs[@]} > keep)) || return 0
  echo "Pruning old backups (keeping $keep)…"
  rm -rf -- "${runs[@]:$keep}"
}
# -----------------------------------------------------------------------------

# 2) Remove any symlinks under $HOME (depth ≤2) that point into DOTFILES_HOME
find "$HOME" -maxdepth 2 -type l -print0 2>/dev/null | while IFS= read -r -d '' L; do
  TARGET=$(readlink "$L")
  if [[ "$TARGET" == "$DOTFILES_HOME"* ]]; then
    echo "Removing stale symlink $L → $TARGET"
    rm -f -- "$L"
  fi
done

# 3) Link all files under DOTFILES_HOME except config/ and bin/
find "$DOTFILES_HOME" -maxdepth 2 -type f \
  ! -path "$DOTFILES_HOME/config/*" \
  ! -path "$DOTFILES_HOME/bin/*" -print0 \
| while IFS= read -r -d '' SRC; do
  NAME=$(basename "$SRC")
  DST="$HOME/$NAME"

  # Backup a real existing target, then link
  backup_if_real "$DST"
  ln -sfn "$SRC" "$DST"
  echo "Linked $DST → $SRC"
done

# 4) Link ONLY the contents of $DOTFILES_HOME/config into ~/.config (no whole-tree link)
mkdir -p "$HOME/.config"

# If ~/.config is a symlink from an older setup, move it aside once
if [ -L "$HOME/.config" ]; then
  mv "$HOME/.config" "$BACKUP/_config_symlink_$(date +%s)"
  mkdir -p "$HOME/.config"
fi

# Link each immediate child (file/dir) from repo → ~/.config
find "$DOTFILES_HOME/config" -mindepth 1 -maxdepth 1 -print0 \
| while IFS= read -r -d '' SRC; do
  name="$(basename "$SRC")"
  DST="$HOME/.config/$name"

  backup_if_real "$DST"
  ln -sfn "$SRC" "$DST"
  echo "Linked $DST → $SRC"
done

# 5) Link any executables under home/bin into ~/.local/bin
if [ -d "$DOTFILES_HOME/bin" ]; then
  mkdir -p "$HOME/.local/bin"

  # remove old bin symlinks pointing into DOTFILES_HOME
  find "$HOME/.local/bin" -maxdepth 1 -type l -print0 2>/dev/null \
  | while IFS= read -r -d '' L; do
      if [[ "$(readlink "$L")" == "$DOTFILES_HOME/bin"* ]]; then
        rm -f -- "$L"
      fi
    done

  # (re)link all files from repo bin/
  find "$DOTFILES_HOME/bin" -maxdepth 1 -type f -print0 \
  | while IFS= read -r -d '' SRC; do
      DST="$HOME/.local/bin/$(basename "$SRC")"
      backup_if_real "$DST"
      ln -sfn "$SRC" "$DST"
      echo "Linked $DST → $SRC"
    done
fi

# 6) TMUX: back up a real ~/.tmux.conf, then link (ignore error if unchanged)
backup_if_real "$HOME/.tmux.conf"
ln -sfn "$HOME/.config/tmux/.tmux.conf" "$HOME/.tmux.conf" || :

# 7) Manually expose selected scripts/setup tools into ~/.local/bin
mkdir -p "$HOME/.local/bin"
for SRC in \
  "$DOTFILES/scripts/ssh_setup.sh" \
  "$DOTFILES/scripts/get_packages.sh" \
  "$DOTFILES/setup/link-dotfiles.sh" \
  "$DOTFILES/scripts/dotfiles-menu.sh" \
  "$DOTFILES/scripts/utils.sh" \
; do
  if [ -f "$SRC" ]; then
    NAME="$(basename "$SRC" .sh)"   # drop .sh for clean names
    DST="$HOME/.local/bin/$NAME"
    backup_if_real "$DST"
    ln -sfn "$SRC" "$DST"
    echo "Linked $DST → $SRC"
  fi
done

# 8) Wrap-up: prune older backups and show paths
prune_old_backups
echo "Backups at: $BACKUP"
echo "Manifest:   $MANIFEST"
echo "Done!"

#!/usr/bin/env bash
set -euo pipefail

# Optional: pass -q to suppress output
QUIET=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    -q|--quiet) QUIET=1; shift ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

log() {
  if [[ $QUIET -eq 0 ]]; then
    echo "$@"
  fi
}

log "Installing packages for $OS_TYPE"

case "$OS_TYPE" in

  nixos)
    (
      set +e
      log "  nix-env: installing base packages"
      nix-env -iA nixpkgs.git   \
                   nixpkgs.zsh   \
                   nixpkgs.neovim
      if [[ $? -ne 0 ]]; then
        echo "Warning: nix-env install failed" >&2
      fi

      if command -v home-manager &>/dev/null; then
        log "  home-manager: applying configuration"
        home-manager switch --flake "$DOTFILES_DIR#$(whoami)" || \
          echo "Warning: home-manager switch failed" >&2
      fi
      set -e
    )
    ;;

  darwin)
    (
      set +e
      if ! command -v brew &>/dev/null; then
        log "  Installing Homebrew"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || \
          echo "Warning: Homebrew install failed" >&2
        eval "$(brew shellenv)" || true
      fi

      if [[ -f "$DOTFILES_DIR/Brewfile" ]]; then
        log "  brew: bundle install"
        brew bundle --file="$DOTFILES_DIR/Brewfile" || \
          echo "Warning: brew bundle failed" >&2
      fi
      set -e
    )
    ;;

  linux)
    (
      set +e
      if [[ -f /etc/debian_version && -f "$DOTFILES_DIR/packages.txt" ]]; then
        PKGS=$(grep -vE '^\s*(#|$)' "$DOTFILES_DIR/packages.txt" | xargs || true)
        if [[ -n "$PKGS" ]]; then
          log "  apt: update && install $PKGS"
          sudo apt update || echo "Warning: apt update failed" >&2
          sudo apt install -y $PKGS || echo "Warning: apt install failed" >&2
        fi
      fi

      if [[ -f "$DOTFILES_DIR/Brewfile" ]]; then
        if ! command -v brew &>/dev/null; then
          log "  Installing Homebrew (Linux)"
          /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || \
            echo "Warning: Homebrew install failed" >&2
          eval "$(brew shellenv)" || true
        fi
        log "  brew: bundle install"
        brew bundle --file="$DOTFILES_DIR/Brewfile" || \
          echo "Warning: brew bundle failed" >&2
      fi
      set -e
    )
    ;;

  *)
    log "Unknown OS_TYPE=$OS_TYPE; skipping package installation"
    ;;
esac

log "Package installation complete"

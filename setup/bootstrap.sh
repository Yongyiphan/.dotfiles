#!/bin/bash

# bootstrap.sh — prep a fresh machine for installs (Debian/Ubuntu/RPi + optional Homebrew)
# Usage:
#   ./bootstrap.sh                  # dry-run
#   ./bootstrap.sh --yes            # do it
#   ./bootstrap.sh --install-brew --yes [--write-shellenv]
set -euo pipefail

DO_IT="no"
WANT_BREW="no"
WRITE_SHELLENV="no"

log(){ printf "\033[1;34m[bootstrap]\033[0m %s\n" "$*" >&2; }
run(){ if [ "$DO_IT" = "yes" ]; then log "exec: $*"; eval "$@"; else log "dry-run: $*"; fi; }
need(){ command -v "$1" >/dev/null 2>&1; }
is_linux(){ [ "$(uname -s)" = "Linux" ]; }
is_darwin(){ [ "$(uname -s)" = "Darwin" ]; }
is_debian(){ [ -e /etc/debian_version ]; }
SUDO=""; [ "$(id -u)" -ne 0 ] && SUDO="sudo"

while [ $# -gt 0 ]; do
  case "$1" in
    -y|--yes) DO_IT="yes";;
    --install-brew) WANT_BREW="yes";;
    --write-shellenv) WRITE_SHELLENV="yes";;
    -h|--help) sed -n '1,120p' "$0" | sed 's/^# //;t;d'; exit 0;;
    *) printf "[error] Unknown arg: %s\n" "$1" >&2; exit 2;;
  esac; shift
done

# APT essentials
if is_linux && is_debian; then
  run "$SUDO apt-get update -y"
  APT_PKGS=(build-essential curl file git ca-certificates procps tar xz-utils unzip pkg-config)
  run "$SUDO apt-get install -y ${APT_PKGS[*]}"
fi

# Ensure ~/.local/bin
run "mkdir -p \$HOME/.local/bin"
case ":$PATH:" in *":$HOME/.local/bin:"*) :;; *) export PATH="$HOME/.local/bin:$PATH";; esac

# Optional Homebrew
if [ "$WANT_BREW" = "yes" ]; then
  if need brew; then
    log "Homebrew already present."
  else
    if is_darwin; then
      run '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
      run 'eval "$(/opt/homebrew/bin/brew shellenv)"'
    elif is_linux; then
      run '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
      if [ -d /home/linuxbrew/.linuxbrew ]; then run 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
      elif [ -d "$HOME/.linuxbrew" ]; then run 'eval "$($HOME/.linuxbrew/bin/brew shellenv)"'
      fi
    fi
  fi
  if need brew && [ "$WRITE_SHELLENV" = "yes" ]; then
    SHELLRC="${ZSH_VERSION:+$HOME/.zshrc}"; SHELLRC="${SHELLRC:-$HOME/.bashrc}"
    BREW_SHELLENV="$(brew shellenv)"
    run "grep -q 'brew shellenv' '$SHELLRC' || { printf '\\n# Homebrew\\n%s\\n' \"$BREW_SHELLENV\" >> '$SHELLRC'; }"
    log "Appended brew shellenv to $SHELLRC"
  fi
fi

log "Bootstrap done. Mode: ${DO_IT^^}"

#!/usr/bin/env bash
# bootstrap.sh — minimal first-run setup for a fresh machine
# Usage:
#   ./setup/bootstrap.sh                 # dry-run
#   ./setup/bootstrap.sh --yes           # execute
#   ./setup/bootstrap.sh --install-brew [--write-shellenv]
#   ./setup/bootstrap.sh --profile <name>   # force a specific profile name
#   ./setup/bootstrap.sh --ssh              # (optional) start/load ssh-agent
#
# What this does (by design, minimal):
#   1) Installs APT essentials (Linux/Debian-family only)
#   2) Optionally installs Homebrew (macOS/Linuxbrew) and writes brew shellenv
#   3) Ensures ~/.local/bin and PATH
#   4) Links dotfiles via setup/link-dotfiles.sh
#   5) Resolves your dotfiles profile (lib/profile.sh or --profile); if missing, CREATES it,
#      then exports DOTFILES_PROFILE so it can be consumed immediately.
#
# What this does NOT do:
#   - No provisioning/version-pin from specs (run your provision step separately)

set -euo pipefail

# -----------------------------
# Flags & helpers
# -----------------------------
DO_IT="no"
WANT_BREW="no"
WRITE_SHELLENV="no"
FORCE_PROFILE=""
RUN_SSH="no"

log(){ printf "\033[1;34m[bootstrap]\033[0m %s\n" "$*" >&2; }
warn(){ printf "\033[1;33m[bootstrap]\033[0m %s\n" "$*" >&2; }
err(){ printf "\033[1;31m[bootstrap]\033[0m %s\n" "$*" >&2; }
run(){ if [ "$DO_IT" = "yes" ]; then log "exec: $*"; eval "$@"; else log "dry-run: $*"; fi; }
need(){ command -v "$1" >/dev/null 2>&1; }
is_linux(){ [ "$(uname -s)" = "Linux" ]; }
is_darwin(){ [ "$(uname -s)" = "Darwin" ]; }
is_debian(){ [ -e /etc/debian_version ]; }

# Resolve repo root even if this file is symlinked
_dotfiles_root() {
  local here="${BASH_SOURCE[0]}"
  while [ -L "$here" ]; do
    local link; link="$(readlink "$here")"
    here="$(cd "$(dirname "$here")" && cd "$(dirname "$link")" && pwd)/$(basename "$link")"
  done
  cd "$(dirname "$here")/.." >/dev/null 2>&1 && pwd
}

while [ $# -gt 0 ]; do
  case "$1" in
    -y|--yes) DO_IT="yes" ;;
    --install-brew) WANT_BREW="yes" ;;
    --write-shellenv) WRITE_SHELLENV="yes" ;;
    -p|--profile) FORCE_PROFILE="${2:-}"; shift ;;
    --ssh) RUN_SSH="yes" ;;
    -h|--help)
      sed -n '1,160p' "$0" | sed 's/^# //;t;d'; exit 0 ;;
    *) err "Unknown arg: $1"; exit 2 ;;
  esac; shift
done

SUDO=""; [ "$(id -u)" -ne 0 ] && SUDO="sudo"
DOTFILES_ROOT="${DOTFILES_ROOT:-$(_dotfiles_root)}"
export DOTFILES_ROOT
log "DOTFILES_ROOT=$DOTFILES_ROOT"

# -----------------------------
# 1) APT essentials (Linux/Debian family)
# -----------------------------
if is_linux && is_debian; then
  run "$SUDO apt-get update -y"
  APT_PKGS=(build-essential curl file git ca-certificates procps tar xz-utils unzip pkg-config)
  run "$SUDO apt-get install -y ${APT_PKGS[*]}"
fi

# -----------------------------
# 2) Optional Homebrew install
# -----------------------------
if [ "$WANT_BREW" = "yes" ]; then
  if need brew; then
    log "Homebrew already present."
  else
    if is_darwin || is_linux; then
      run '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
      if is_darwin; then
        run 'eval "$(/opt/homebrew/bin/brew shellenv)"'
      else
        if [ -d /home/linuxbrew/.linuxbrew ]; then
          run 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
        elif [ -d "$HOME/.linuxbrew" ]; then
          run 'eval "$($HOME/.linuxbrew/bin/brew shellenv)"'
        fi
      fi
    fi
  fi
  if need brew && [ "$WRITE_SHELLENV" = "yes" ]; then
    SHELLRC="${ZSH_VERSION:+$HOME/.zshrc}"; SHELLRC="${SHELLRC:-$HOME/.bashrc}"
    run 'BREW_SHELLENV="$(brew shellenv)"'
    run "grep -q 'brew shellenv' '$SHELLRC' || { printf '\\n# Homebrew\\n%s\\n' \"\$BREW_SHELLENV\" >> '$SHELLRC'; }"
    log "Appended brew shellenv to $SHELLRC"
  fi
fi

# -----------------------------
# 3) Ensure ~/.local/bin on PATH
# -----------------------------
run "mkdir -p \"\$HOME/.local/bin\""
case ":${PATH:-}:" in
  *":$HOME/.local/bin:"*) : ;;
  *) export PATH="$HOME/.local/bin:$PATH";;
esac

# -----------------------------
# 4) Link dotfiles (idempotent)
# -----------------------------
LINKER="$DOTFILES_ROOT/setup/link-dotfiles.sh"
if [ -x "$LINKER" ]; then
  run "\"$LINKER\""
else
  warn "Linker not found at $LINKER — skipping link step."
fi

# -----------------------------
# 5) Resolve profile; if missing, CREATE it; then export DOTFILES_PROFILE
# -----------------------------
# Source your resolver if present
if [ -f "$DOTFILES_ROOT/lib/profile.sh" ]; then
  # shellcheck disable=SC1090
  . "$DOTFILES_ROOT/lib/profile.sh"
fi

# Resolve name: forced via CLI > get_profile_name() > fallback pattern
_profile_default_name() {
  local host user distro mid=""
  host="$(hostnamectl --static 2>/dev/null || hostname -s 2>/dev/null || uname -n)"
  user="$(id -un 2>/dev/null || echo "${USER:-unknown}")"
  if [ -r /etc/os-release ]; then . /etc/os-release; distro="${ID:-linux}"; else distro="unknown"; fi
  [ -n "${WSL_DISTRO_NAME:-}" ] && distro="${distro}-wsl"
  printf '%s_%s_%s\n' "$(echo "$host"   | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]_-' '_')" \
                       "$(echo "$user"   | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]_-' '_')" \
                       "$(echo "$distro" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]_-' '_')"
}

# -----------------------------
# 5) Resolve profile; create skeleton on first run; export DOTFILES_PROFILE
# -----------------------------
# (resolver sourcing happens earlier in your script)
PROFILE_NAME="${PROFILE_NAME:-$FORCE_PROFILE}"
if [ -z "$PROFILE_NAME" ]; then
  if declare -F get_profile_name >/dev/null 2>&1; then
    PROFILE_NAME="$(get_profile_name || true)"
  else
    # fallback pattern
    host="$(hostnamectl --static 2>/dev/null || hostname -s 2>/dev/null || uname -n)"
    user="$(id -un 2>/dev/null || echo "${USER:-unknown}")"
    if [ -r /etc/os-release ]; then . /etc/os-release; distro="${ID:-linux}"; else distro="unknown"; fi
    [ -n "${WSL_DISTRO_NAME:-}" ] && distro="${distro}-wsl"
    PROFILE_NAME="$(printf '%s_%s_%s\n' \
      "$(echo "$host"   | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]_-' '_')" \
      "$(echo "$user"   | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]_-' '_')" \
      "$(echo "$distro" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]_-' '_')")"
  fi
fi

PROFILE_DIR="$DOTFILES_ROOT/profiles/$PROFILE_NAME"
SPEC_DIR="$PROFILE_DIR/specs"

if [ -d "$PROFILE_DIR" ]; then
  export DOTFILES_PROFILE="$PROFILE_NAME"
  log "DOTFILES_PROFILE=$DOTFILES_PROFILE (existing)"
else
  log "== DRY-RUN PREVIEW: create profile skeleton at $PROFILE_DIR =="
  run "mkdir -p \"$SPEC_DIR\" \"$PROFILE_DIR/home\" \"$PROFILE_DIR/lsp/settings\""
  run "printf 'return { }\\n' > \"$PROFILE_DIR/plugins.lua\""
  run "printf 'return { names = { } }\\n' > \"$PROFILE_DIR/lsp/settings.lua\""
  run "printf '# per-profile exports go here\\n' > \"$PROFILE_DIR/ENV\""

  if [ "$DO_IT" = "yes" ]; then
    export DOTFILES_PROFILE="$PROFILE_NAME"
    log "DOTFILES_PROFILE=$DOTFILES_PROFILE (created)"
  else
    log "Dry-run only — nothing created. Re-run with --yes to create $PROFILE_DIR."
  fi
fi

# -----------------------------
# 6) Optional: bring up ssh-agent now
# -----------------------------
if [ "$RUN_SSH" = "yes" ]; then
  SSH_HELPER="$DOTFILES_ROOT/scripts/ssh_setup.sh"
  if [ -x "$SSH_HELPER" ]; then
    run "\"$SSH_HELPER\""
  else
    warn "ssh_setup.sh not found/executable at $SSH_HELPER — skipping ssh step."
  fi
fi

log "Bootstrap complete. Mode: ${DO_IT^^}"


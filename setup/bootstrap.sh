#!/usr/bin/env bash
# bootstrap.sh — tracked first-run setup for tmux + Neovim
#
# Live contract:
#   1) resolve the active profile
#   2) install tracked packages from core + profile catalogs
#   3) install the bootstrap-owned Neovim runtime
#   4) link dotfiles
#   5) optionally prewarm tmux/Neovim
#   6) freeze observed package-manager state and write drift reports

set -euo pipefail

DO_IT="no"
FORCE_PROFILE=""
RUN_SSH="no"
SKIP_INSTALL="no"
SKIP_LINK="no"
SKIP_PREWARM="no"
AUDIT_ONLY="no"

log(){ printf "\033[1;34m[bootstrap]\033[0m %s\n" "$*" >&2; }
warn(){ printf "\033[1;33m[bootstrap]\033[0m %s\n" "$*" >&2; }
err(){ printf "\033[1;31m[bootstrap]\033[0m %s\n" "$*" >&2; }

run_cmd() {
  if [ "$DO_IT" = "yes" ]; then
    log "exec: $*"
    eval "$@"
  else
    log "dry-run: $*"
  fi
}

_dotfiles_root() {
  local here="${BASH_SOURCE[0]}"
  while [ -L "$here" ]; do
    local link
    link="$(readlink "$here")"
    here="$(cd "$(dirname "$here")" && cd "$(dirname "$link")" && pwd)/$(basename "$link")"
  done
  cd "$(dirname "$here")/.." >/dev/null 2>&1 && pwd
}

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

  --yes, -y            Execute changes instead of dry-run
  --profile NAME       Force a specific profile name
  --ssh                Run ssh_setup.sh after linking
  --skip-install       Skip tracked package install + Neovim core install
  --skip-link          Skip dotfile linking
  --skip-prewarm       Skip tmux/Neovim prewarm
  --freeze-only        Only freeze observed state and write audit outputs
  --audit-only         Alias for --freeze-only
  -h, --help           Show this help
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    -y|--yes) DO_IT="yes" ;;
    -p|--profile) FORCE_PROFILE="${2:-}"; shift ;;
    --ssh) RUN_SSH="yes" ;;
    --skip-install) SKIP_INSTALL="yes" ;;
    --skip-link) SKIP_LINK="yes" ;;
    --skip-prewarm) SKIP_PREWARM="yes" ;;
    --freeze-only|--audit-only)
      AUDIT_ONLY="yes"
      SKIP_INSTALL="yes"
      SKIP_LINK="yes"
      SKIP_PREWARM="yes"
      ;;
    -h|--help) usage; exit 0 ;;
    *) err "Unknown arg: $1"; exit 2 ;;
  esac
  shift
done

DOTFILES_ROOT="${DOTFILES_ROOT:-$(_dotfiles_root)}"
export DOTFILES_ROOT

if [ ! -f "$DOTFILES_ROOT/lib/profile.sh" ]; then
  err "Missing profile resolver at $DOTFILES_ROOT/lib/profile.sh"
  exit 1
fi
if [ ! -f "$DOTFILES_ROOT/setup/resolve_catalog.sh" ]; then
  err "Missing catalog resolver at $DOTFILES_ROOT/setup/resolve_catalog.sh"
  exit 1
fi

# shellcheck disable=SC1090
. "$DOTFILES_ROOT/lib/profile.sh"
# shellcheck disable=SC1090
. "$DOTFILES_ROOT/setup/resolve_catalog.sh"

PROFILE_NAME="${FORCE_PROFILE:-$(get_profile_name)}"
PROFILE_DIR="$DOTFILES_ROOT/profiles/$PROFILE_NAME"
SPEC_DIR="$PROFILE_DIR/specs"
CORE_SPEC_DIR="$DOTFILES_ROOT/profiles/core/specs"
CORE_CATALOG="$CORE_SPEC_DIR/catalog.lock"
PROFILE_CATALOG="$SPEC_DIR/catalog.lock"
TMP_MANIFEST=""

cleanup() {
  if [ -n "$TMP_MANIFEST" ] && [ -f "$TMP_MANIFEST" ]; then
    rm -f "$TMP_MANIFEST"
  fi
  return 0
}
trap cleanup EXIT

ensure_profile_scaffold() {
  mkdir -p "$CORE_SPEC_DIR" "$SPEC_DIR"

  if [ ! -f "$CORE_CATALOG" ]; then
    catalog_default_scaffold > "$CORE_CATALOG"
  fi

  if [ ! -f "$PROFILE_DIR/ENV" ]; then
    : > "$PROFILE_DIR/ENV"
  fi

  if [ ! -f "$PROFILE_CATALOG" ]; then
    catalog_default_scaffold > "$PROFILE_CATALOG"
  fi

  if [ ! -f "$SPEC_DIR/tarball.specs" ]; then
    cat > "$SPEC_DIR/tarball.specs" <<'EOF'
# tarball.specs (optional)
# One per line: name[=version] [url=...]
EOF
  fi
}

preview_scaffold() {
  if [ ! -d "$PROFILE_DIR" ]; then
    log "profile scaffold would be created at $PROFILE_DIR"
  fi
  if [ ! -f "$CORE_CATALOG" ]; then
    log "core catalog would be created at $CORE_CATALOG"
  fi
  if [ ! -f "$PROFILE_CATALOG" ]; then
    log "profile catalog would be created at $PROFILE_CATALOG"
  fi
}

prewarm_tmux() {
  local tpm_dir="$HOME/.tmux/plugins/tpm"
  if [ ! -d "$tpm_dir" ] && command -v git >/dev/null 2>&1; then
    log "prewarm: cloning TPM"
    git clone https://github.com/tmux-plugins/tpm "$tpm_dir" >/dev/null 2>&1 || warn "TPM clone failed; continuing"
  fi
  if [ -x "$tpm_dir/bin/install_plugins" ]; then
    log "prewarm: installing tmux plugins"
    TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins/" "$tpm_dir/bin/install_plugins" >/dev/null 2>&1 || warn "tmux plugin prewarm failed; continuing"
  fi
}

prewarm_nvim() {
  local nvim_bin=""
  if [ -x "$HOME/.local/bin/nvim" ]; then
    nvim_bin="$HOME/.local/bin/nvim"
  elif command -v nvim >/dev/null 2>&1; then
    nvim_bin="$(command -v nvim)"
  fi
  [ -n "$nvim_bin" ] || return 0

  log "prewarm: syncing Neovim plugins"
  "$nvim_bin" --headless "+Lazy! sync" "+qa" >/dev/null 2>&1 || warn "Neovim Lazy sync failed; continuing"
  log "prewarm: updating Treesitter parsers"
  "$nvim_bin" --headless "+TSUpdateSync" "+qa" >/dev/null 2>&1 || warn "Neovim TSUpdateSync failed; continuing"
}

if [ "$DO_IT" = "yes" ]; then
  ensure_profile_scaffold
else
  preview_scaffold
fi

export DOTFILES_PROFILE="$PROFILE_NAME"
log "DOTFILES_ROOT=$DOTFILES_ROOT"
log "DOTFILES_PROFILE=$DOTFILES_PROFILE"

if [ "$AUDIT_ONLY" = "yes" ]; then
  if [ "$DO_IT" = "yes" ]; then
    "$DOTFILES_ROOT/setup/freeze_catalog.sh" --profile "$PROFILE_NAME" --init
  else
    log "dry-run: \"$DOTFILES_ROOT/setup/freeze_catalog.sh\" --profile \"$PROFILE_NAME\" --init"
  fi
  log "Bootstrap complete. Mode: ${DO_IT^^}"
  exit 0
fi

TMP_MANIFEST="$(mktemp)"
catalog_write_install_manifest "$CORE_CATALOG" "$PROFILE_CATALOG" "$TMP_MANIFEST"

if [ "$SKIP_INSTALL" = "no" ]; then
  if [ "$DO_IT" = "yes" ]; then
    "$DOTFILES_ROOT/setup/pkg_install.sh" -f "$TMP_MANIFEST" --yes
    "$DOTFILES_ROOT/setup/install-core.sh"
  else
    log "dry-run: \"$DOTFILES_ROOT/setup/pkg_install.sh\" -f \"$TMP_MANIFEST\""
    log "dry-run: \"$DOTFILES_ROOT/setup/install-core.sh\""
  fi
fi

if [ "$SKIP_LINK" = "no" ]; then
  if [ "$DO_IT" = "yes" ]; then
    "$DOTFILES_ROOT/setup/link-dotfiles.sh"
  else
    log "dry-run: \"$DOTFILES_ROOT/setup/link-dotfiles.sh\""
  fi
fi

if [ "$RUN_SSH" = "yes" ]; then
  if [ -x "$DOTFILES_ROOT/scripts/ssh_setup.sh" ]; then
    if [ "$DO_IT" = "yes" ]; then
      "$DOTFILES_ROOT/scripts/ssh_setup.sh"
    else
      log "dry-run: \"$DOTFILES_ROOT/scripts/ssh_setup.sh\""
    fi
  else
    warn "ssh_setup.sh not found or not executable; skipping"
  fi
fi

if [ "$SKIP_PREWARM" = "no" ]; then
  if [ "$DO_IT" = "yes" ]; then
    prewarm_tmux
    prewarm_nvim
  else
    log "dry-run: prewarm tmux"
    log "dry-run: prewarm nvim"
  fi
fi

if [ "$DO_IT" = "yes" ]; then
  "$DOTFILES_ROOT/setup/freeze_catalog.sh" --profile "$PROFILE_NAME" --init
else
  log "dry-run: \"$DOTFILES_ROOT/setup/freeze_catalog.sh\" --profile \"$PROFILE_NAME\" --init"
fi

log "Bootstrap complete. Mode: ${DO_IT^^}"

#!/usr/bin/env bash
# Freeze package-manager state for the active or selected dotfiles profile.
# This script captures raw package-manager snapshots, then writes normalized
# resolved state and drift reports against the tracked catalog manifests.

set -euo pipefail

_dotfiles_root() {
  local here="${BASH_SOURCE[0]}"
  while [ -L "$here" ]; do
    local link
    link="$(readlink "$here")"
    here="$(cd "$(dirname "$here")" && cd "$(dirname "$link")" && pwd)/$(basename "$link")"
  done
  cd "$(dirname "$here")/.." >/dev/null 2>&1 && pwd
}

DOTFILES_ROOT="${DOTFILES_ROOT:-${DOTFILES:-$(_dotfiles_root)}}"

if [ ! -f "$DOTFILES_ROOT/lib/profile.sh" ]; then
  echo "freeze_catalog: missing $DOTFILES_ROOT/lib/profile.sh" >&2
  exit 1
fi
if [ ! -f "$DOTFILES_ROOT/setup/resolve_catalog.sh" ]; then
  echo "freeze_catalog: missing $DOTFILES_ROOT/setup/resolve_catalog.sh" >&2
  exit 1
fi

# shellcheck disable=SC1090
. "$DOTFILES_ROOT/lib/profile.sh"
# shellcheck disable=SC1090
. "$DOTFILES_ROOT/setup/resolve_catalog.sh"

usage() {
  cat <<EOF
Usage: $(basename "$0") [--profile NAME] [--init]

  --profile NAME   Use this profile name instead of the computed get_profile_name()
  --init           Create a minimal profile scaffold if missing
EOF
}

PROFILE_OVERRIDE=""
INIT=0
while (($#)); do
  case "$1" in
    --profile) PROFILE_OVERRIDE="${2:-}"; shift 2 ;;
    --init) INIT=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 1 ;;
  esac
done

PROFILE_NAME="${PROFILE_OVERRIDE:-$(get_profile_name)}"
PROFILE_DIR="$DOTFILES_ROOT/profiles/$PROFILE_NAME"
SPEC_DIR="$PROFILE_DIR/specs"
CORE_SPEC_DIR="$DOTFILES_ROOT/profiles/core/specs"
CORE_CATALOG="$CORE_SPEC_DIR/catalog.lock"
PROFILE_CATALOG="$SPEC_DIR/catalog.lock"
APT_FILE="$SPEC_DIR/apt.manual.versions.txt"
BREW_FILE="$SPEC_DIR/brew.leaves.versions.txt"
RESOLVED_FILE="$SPEC_DIR/resolved.lock.tsv"
REPORT_FILE="$SPEC_DIR/resolve-report.tsv"

if [ ! -d "$PROFILE_DIR" ] && [ "$INIT" -ne 1 ]; then
  echo "freeze_catalog: profile '$PROFILE_NAME' does not exist; use --init to create it." >&2
  exit 1
fi

mkdir -p "$CORE_SPEC_DIR"
if [ ! -f "$CORE_CATALOG" ]; then
  catalog_default_scaffold > "$CORE_CATALOG"
fi

if [ ! -d "$PROFILE_DIR" ]; then
  mkdir -p "$SPEC_DIR"
  : > "$PROFILE_DIR/ENV"
fi

mkdir -p "$SPEC_DIR"
if [ ! -f "$PROFILE_CATALOG" ]; then
  catalog_default_scaffold > "$PROFILE_CATALOG"
fi
if [ ! -f "$SPEC_DIR/tarball.specs" ]; then
  cat > "$SPEC_DIR/tarball.specs" <<'EOF'
# tarball.specs (optional)
# One per line: name[=version] [url=...]
# Examples:
# ripgrep=14.1.0 url=https://github.com/BurntSushi/ripgrep/releases/download/14.1.0/ripgrep-14.1.0-aarch64-unknown-linux-musl.tar.gz
# hugo=0.133.1  url=https://github.com/gohugoio/hugo/releases/download/v0.133.1/hugo_extended_0.133.1_Linux-ARM64.tar.gz
EOF
fi

export DOTFILES_PROFILE="$PROFILE_NAME"
export CATALOG_SKIP_BREW=0

echo "== Freeze specs to: $SPEC_DIR =="
echo "   Profile: $DOTFILES_PROFILE"

if command -v apt >/dev/null 2>&1; then
  echo "-> Capturing APT manual packages + versions"
  apt-mark showmanual \
    | sort \
    | while read -r pkg; do
        [ -n "$pkg" ] || continue
        version="$(dpkg-query -W -f='${Version}' "$pkg" 2>/dev/null || true)"
        if [ -n "$version" ]; then
          printf "%s %s\n" "$pkg" "$version"
        else
          printf "%s\n" "$pkg"
        fi
      done > "$APT_FILE"
  echo "   Wrote $APT_FILE"
else
  echo "-> APT not found; skipping apt.manual.versions.txt"
fi

if command -v brew >/dev/null 2>&1; then
  echo "-> Capturing Homebrew leaves + versions"
  tmp_leaves="$(mktemp)"
  trap 'rm -f "$tmp_leaves"' EXIT
  if HOMEBREW_NO_AUTO_UPDATE=1 brew leaves > "$tmp_leaves" 2>/dev/null; then
    : > "$BREW_FILE"
    while read -r formula version _; do
      [ -n "$formula" ] || continue
      if grep -qx "$formula" "$tmp_leaves"; then
        printf "%s %s\n" "$formula" "${version:-}" >> "$BREW_FILE"
      fi
    done < <(HOMEBREW_NO_AUTO_UPDATE=1 brew list --versions 2>/dev/null)
    while read -r formula; do
      grep -q "^$formula " "$BREW_FILE" || printf "%s\n" "$formula" >> "$BREW_FILE"
    done < "$tmp_leaves"
    echo "   Wrote $BREW_FILE"
  else
    export CATALOG_SKIP_BREW=1
    echo "-> Homebrew available but not readable without side effects; skipping brew.leaves.versions.txt"
  fi
else
  export CATALOG_SKIP_BREW=1
  echo "-> Homebrew not found; skipping brew.leaves.versions.txt"
fi

catalog_write_audit_outputs \
  "$CORE_CATALOG" \
  "$PROFILE_CATALOG" \
  "$APT_FILE" \
  "$BREW_FILE" \
  "$RESOLVED_FILE" \
  "$REPORT_FILE"

echo "-> Wrote $RESOLVED_FILE"
echo "-> Wrote $REPORT_FILE"
echo "Done."

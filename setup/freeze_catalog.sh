#!/usr/bin/env bash
# ~/.dotfiles/scripts/freeze_catalog.sh
# Capture package "specs" for the *active* dotfiles profile.
# - By default, requires the profile to already exist (no silent creation).
# - Optional --profile NAME to override.
# - Optional --init to create the profile skeleton iff missing.

set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"

usage() {
  cat <<EOF
Usage: $(basename "$0") [--profile NAME] [--init]

  --profile NAME   Use this profile name instead of the computed get_profile_name()
  --init           If the profile directory is missing, create: ENV + specs/ + startup.d/

Examples:
  $(basename "$0")
  $(basename "$0") --profile <PROFILE_NAME> 
  $(basename "$0") --init
EOF
}

# ---------------- args ----------------
PROFILE_OVERRIDE=""
INIT=0
while (($#)); do
  case "$1" in
    --profile) PROFILE_OVERRIDE="${2:-}"; shift 2 ;;
    --init)    INIT=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 1 ;;
  esac
done

# ---------------- load profile env (strict) ----------------
# This file is your strict loader that uses get_profile_name() with no legacy fallback.
# It also defines dot_env_path and dot_load_env.
if [[ ! -f "$DOTFILES/scripts/load-env.sh" ]]; then
  echo "freeze_catalog: missing $DOTFILES/scripts/load-env.sh" >&2
  exit 1
fi
# shellcheck source=/dev/null
. "$DOTFILES/scripts/load-env.sh"

# Detect which base the loader is using by asking for ENV path.
_profile_env_path() {
  # If PROFILE_OVERRIDE is set, we pass it through; dot_load_env will validate existence.
  if dot_load_env "${PROFILE_OVERRIDE:-}"; then
    dot_env_path "$DOTFILES_PROFILE"
  else
    return 1
  fi
}

# Try to load; if it fails and --init was requested, create skeleton, then retry.
if ! ENV_PATH="$(_profile_env_path)"; then
  if (( INIT )); then
    # Figure out the intended name (explicit override > env > computed)
    if [[ -n "$PROFILE_OVERRIDE" ]]; then
      PNAME="$PROFILE_OVERRIDE"
    elif declare -F get_profile_name >/dev/null 2>&1; then
      PNAME="$(get_profile_name)"
    else
      echo "freeze_catalog: get_profile_name() not available; cannot --init" >&2
      exit 1
    fi

    # Choose the same base the loader prefers: profiles/ then profile/
    PROFILES_BASE="$DOTFILES/profiles"
    [[ -d "$PROFILES_BASE" ]] || PROFILES_BASE="$DOTFILES/profile"
    [[ -d "$PROFILES_BASE" ]] || { echo "freeze_catalog: profiles base not found" >&2; exit 1; }

    mkdir -p "$PROFILES_BASE/$PNAME"/{specs,startup.d}
    : > "$PROFILES_BASE/$PNAME/ENV"
    echo "Initialized profile: $PROFILES_BASE/$PNAME"

    # Retry load
    ENV_PATH="$(_profile_env_path)" || { echo "freeze_catalog: failed to load profile after --init" >&2; exit 1; }
  else
    echo "freeze_catalog: could not load profile; run with --init to create one." >&2
    exit 1
  fi
fi

PROFILE_DIR="$(dirname "$ENV_PATH")"     # .../<profile>
SPEC_DIR="$PROFILE_DIR/specs"
mkdir -p "$SPEC_DIR"

echo "== Freeze specs to: $SPEC_DIR =="
echo "   Profile: $DOTFILES_PROFILE"
echo "   ENV:     $ENV_PATH"

# ---------------- APT packages (manual + versions) ----------------
if command -v apt >/dev/null 2>&1; then
  echo "-> Capturing APT manual packages + versions"
  apt-mark showmanual \
    | sort \
    | while read -r p; do
        [[ -z "$p" ]] && continue
        v="$(dpkg-query -W -f='${Version}' "$p" 2>/dev/null || true)"
        if [[ -n "$v" ]]; then printf "%s %s\n" "$p" "$v"; else printf "%s\n" "$p"; fi
      done \
    > "$SPEC_DIR/apt.manual.versions.txt"
  echo "   Wrote $SPEC_DIR/apt.manual.versions.txt"
else
  echo "-> APT not found; skipping apt.manual.versions.txt"
fi

# ---------------- Homebrew (leaves + versions) ----------------
if command -v brew >/dev/null 2>&1; then
  echo "-> Capturing Homebrew leaves + versions"
  if command -v jq >/dev/null 2>&1; then
    : > "$SPEC_DIR/brew.leaves.versions.txt"
    while read -r f; do
      [[ -z "$f" ]] && continue
      ver="$(brew info --json=v2 "$f" | jq -r '.formulae[0].installed[-1].version // ""')"
      printf "%s %s\n" "$f" "$ver" >> "$SPEC_DIR/brew.leaves.versions.txt"
    done < <(brew leaves)
  else
    tmp_leaves="$(mktemp)"; trap 'rm -f "$tmp_leaves"' EXIT
    brew leaves > "$tmp_leaves"
    : > "$SPEC_DIR/brew.leaves.versions.txt"
    while read -r f ver _; do
      [[ -z "$f" ]] && continue
      if grep -qx "$f" "$tmp_leaves"; then
        printf "%s %s\n" "$f" "${ver:-}" >> "$SPEC_DIR/brew.leaves.versions.txt"
      fi
    done < <(brew list --versions)
    while read -r f; do
      grep -q "^$f " "$SPEC_DIR/brew.leaves.versions.txt" || printf "%s\n" "$f" >> "$SPEC_DIR/brew.leaves.versions.txt"
    done < "$tmp_leaves"
  fi
  echo "   Wrote $SPEC_DIR/brew.leaves.versions.txt"
else
  echo "-> Homebrew not found; skipping brew.leaves.versions.txt"
fi

# ---------------- Tarball scaffold (optional) ----------------
if [[ ! -f "$SPEC_DIR/tarball.specs" ]]; then
  cat > "$SPEC_DIR/tarball.specs" <<'EOF'
# tarball.specs (optional)
# One per line: name[=version] [url=...]
# Examples:
# ripgrep=14.1.0 url=https://github.com/BurntSushi/ripgrep/releases/download/14.1.0/ripgrep-14.1.0-aarch64-unknown-linux-musl.tar.gz
# hugo=0.133.1  url=https://github.com/gohugoio/hugo/releases/download/v0.133.1/hugo_extended_0.133.1_Linux-ARM64.tar.gz
EOF
  echo "-> Created $SPEC_DIR/tarball.specs (scaffold)"
fi

echo "Done."


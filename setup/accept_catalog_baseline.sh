#!/usr/bin/env bash
# Promote the current observed profile snapshots into the tracked baseline files.

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
  echo "accept_catalog_baseline: missing $DOTFILES_ROOT/lib/profile.sh" >&2
  exit 1
fi

# shellcheck disable=SC1090
. "$DOTFILES_ROOT/lib/profile.sh"

DO_IT="no"
REFRESH="no"
INIT=0
PROFILE_OVERRIDE=""

usage() {
  cat <<EOF
Usage: $(basename "$0") [--profile NAME] [--refresh] [--init] [--yes]

  --profile NAME   Use this profile name instead of the computed get_profile_name()
  --refresh        Run freeze_catalog.sh first to refresh observed snapshots
  --init           Create the profile scaffold if missing
  --yes            Promote observed snapshots into the tracked baseline files
EOF
}

while (($#)); do
  case "$1" in
    --profile) PROFILE_OVERRIDE="${2:-}"; shift 2 ;;
    --refresh) REFRESH="yes"; shift ;;
    --init) INIT=1; shift ;;
    --yes) DO_IT="yes"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 1 ;;
  esac
done

PROFILE_NAME="${PROFILE_OVERRIDE:-$(get_profile_name)}"
PROFILE_DIR="$DOTFILES_ROOT/profiles/$PROFILE_NAME"
SPEC_DIR="$PROFILE_DIR/specs"
OBSERVED_DIR="$SPEC_DIR/.observed"
OBSERVED_APT_FILE="$OBSERVED_DIR/apt.manual.versions.txt"
OBSERVED_BREW_FILE="$OBSERVED_DIR/brew.leaves.versions.txt"
BASELINE_APT_FILE="$SPEC_DIR/apt.manual.versions.txt"
BASELINE_BREW_FILE="$SPEC_DIR/brew.leaves.versions.txt"
BASELINE_REPORT_FILE="$OBSERVED_DIR/baseline-report.tsv"

if [ "$REFRESH" = "yes" ]; then
  args=(--profile "$PROFILE_NAME")
  [ "$INIT" -eq 1 ] && args+=(--init)
  "$DOTFILES_ROOT/setup/freeze_catalog.sh" "${args[@]}"
fi

if [ ! -d "$OBSERVED_DIR" ]; then
  echo "accept_catalog_baseline: missing observed snapshot dir $OBSERVED_DIR" >&2
  exit 1
fi

echo "== Baseline acceptance preview for $PROFILE_NAME =="
echo "   Baseline dir: $SPEC_DIR"
echo "   Observed dir: $OBSERVED_DIR"

if [ -f "$BASELINE_REPORT_FILE" ]; then
  echo "-> Baseline delta summary"
  awk 'BEGIN{FS="\t"} NR>1 {counts[$5]++} END {for (k in counts) printf "   %s: %d\n", k, counts[k]}' "$BASELINE_REPORT_FILE" | sort || true
else
  echo "-> No baseline delta report found"
fi

promote_file() {
  local src="$1" dst="$2" label="$3"
  if [ ! -f "$src" ]; then
    echo "-> No observed $label snapshot to accept"
    return 0
  fi
  if [ "$DO_IT" = "yes" ]; then
    cp "$src" "$dst"
    echo "-> Accepted $label baseline: $dst"
  else
    echo "-> Dry-run: would accept $label baseline: $dst"
  fi
}

promote_file "$OBSERVED_APT_FILE" "$BASELINE_APT_FILE" "APT"
promote_file "$OBSERVED_BREW_FILE" "$BASELINE_BREW_FILE" "Brew"

if [ "$DO_IT" = "yes" ]; then
  echo "Baseline acceptance complete."
else
  echo "Dry-run only. Re-run with --yes to accept the observed baseline."
fi

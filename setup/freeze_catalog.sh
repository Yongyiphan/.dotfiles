#!/usr/bin/env bash
set -euo pipefail

# Where your repo lives
DOTFILES="${DOTFILES:-$HOME/.dotfiles}"

# Profile path: ~/.dotfiles/profile/<host>_<distro>/specs
host="$(hostname -s || hostname)"
if [[ -r /etc/os-release ]]; then . /etc/os-release; distro_id="${ID:-unknown}"; else distro_id="unknown"; fi
profile="${DOTFILES}/profile/${host}_${distro_id}"
specdir="$profile/specs"
mkdir -p "$specdir"

echo "== Freeze specs to: $specdir =="

# --- APT: manual packages with versions --------------------------------------
if command -v apt >/dev/null 2>&1; then
  echo "-> Capturing APT manual packages + versions"
  # Note: this is the raw manual set (RPi OS ships many as manual by default).
  # You can curate later by editing the file.
  apt-mark showmanual \
    | sort \
    | while read -r p; do
        [[ -z "$p" ]] && continue
        v="$(dpkg-query -W -f='${Version}' "$p" 2>/dev/null || true)"
        if [[ -n "$v" ]]; then printf "%s %s\n" "$p" "$v"; else printf "%s\n" "$p"; fi
      done \
    > "$specdir/apt.manual.versions.txt"
  echo "   Wrote $specdir/apt.manual.versions.txt"
else
  echo "-> APT not found; skipping apt.manual.versions.txt"
fi

# --- Homebrew: leaves with versions ------------------------------------------
if command -v brew >/dev/null 2>&1; then
  echo "-> Capturing Homebrew leaves + versions"
  if command -v jq >/dev/null 2>&1; then
    # Precise via JSON (preferred)
    : > "$specdir/brew.leaves.versions.txt"
    while read -r f; do
      [[ -z "$f" ]] && continue
      ver="$(brew info --json=v2 "$f" | jq -r '.formulae[0].installed[-1].version // ""')"
      printf "%s %s\n" "$f" "$ver" >> "$specdir/brew.leaves.versions.txt"
    done < <(brew leaves)
  else
    # Fallback: version may be approximate or blank
    # Write "formula version" if we can parse it, else just "formula"
    tmp_leaves="$(mktemp)"; trap 'rm -f "$tmp_leaves"' EXIT
    brew leaves > "$tmp_leaves"
    : > "$specdir/brew.leaves.versions.txt"
    # Try to join with `brew list --versions`
    while read -r f ver _; do
      [[ -z "$f" ]] && continue
      if grep -qx "$f" "$tmp_leaves"; then
        printf "%s %s\n" "$f" "${ver:-}" >> "$specdir/brew.leaves.versions.txt"
      fi
    done < <(brew list --versions)
    # Add any leaves missing a version line
    while read -r f; do
      grep -q "^$f " "$specdir/brew.leaves.versions.txt" || printf "%s\n" "$f" >> "$specdir/brew.leaves.versions.txt"
    done < "$tmp_leaves"
  fi
  echo "   Wrote $specdir/brew.leaves.versions.txt"
else
  echo "-> Homebrew not found; skipping brew.leaves.versions.txt"
fi

# --- Tarball scaffold (left empty for now) ------------------------------------
if [[ ! -f "$specdir/tarball.specs" ]]; then
  cat > "$specdir/tarball.specs" <<'EOF'
# tarball.specs (optional)
# One per line: name[=version] [url=...]   # leave blank if you don't use tarballs yet
# Examples:
# ripgrep=14.1.0 url=https://github.com/BurntSushi/ripgrep/releases/download/14.1.0/ripgrep-14.1.0-aarch64-unknown-linux-musl.tar.gz
# hugo=0.133.1  url=https://github.com/gohugoio/hugo/releases/download/v0.133.1/hugo_extended_0.133.1_Linux-ARM64.tar.gz
EOF
  echo "-> Created $specdir/tarball.specs (scaffold)"
fi

# --- Do NOT build catalog.lock anymore ----------------------------------------
# If an old catalog.lock exists and confuses your installer, comment or remove it:
if [[ -f "$specdir/catalog.lock" ]]; then
  echo "(!) Note: $specdir/catalog.lock exists. Your installer can ignore it now."
  echo "    Consider renaming it if you want to be 100% sure:"
  echo "      mv '$specdir/catalog.lock' '$specdir/catalog.lock.bak'"
fi

echo "Done."

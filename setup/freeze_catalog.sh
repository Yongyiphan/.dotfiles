#!/usr/bin/env bash
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
host="$(hostname -s || hostname)"
distro_id="$(. /etc/os-release; echo "${ID:-unknown}")"
profile="${DOTFILES}/profile/${host}_${distro_id}"
specdir="$profile/specs"

mkdir -p "$specdir"

# --- Freeze APT manual packages with versions ---
echo "== Freezing APT manual packages with versions =="
if command -v apt >/dev/null 2>&1; then
  apt-mark showmanual \
  | sort \
  | xargs -r -n1 bash -lc 'p="$1"; v=$(dpkg-query -W -f="\${Version}" "$p" 2>/dev/null || true); [ -n "$v" ] && echo "$p $v" || echo "$p";' _ \
  > "$specdir/apt.manual.versions.txt"
  echo "Wrote $specdir/apt.manual.versions.txt"
fi

# --- Freeze Homebrew leaves with versions ---
echo "== Freezing Homebrew leaves with versions =="
if command -v brew >/dev/null 2>&1; then
  brew leaves \
  | xargs -I{} sh -c 'printf "%s %s\n" "{}" "$(brew info --json=v2 "{}" | jq -r ".formulae[0].installed[-1].version // \"unknown\"")"' \
  > "$specdir/brew.leaves.versions.txt" || true
  echo "Wrote $specdir/brew.leaves.versions.txt"
fi

# --- Ensure tarball.specs scaffold exists ---
[ -f "$specdir/tarball.specs" ] || cat > "$specdir/tarball.specs" <<'EOF'
# name|version|url|strip_components|bin_globs
# Example:
# ripgrep|14.1.0|https://github.com/BurntSushi/ripgrep/releases/download/14.1.0/ripgrep-14.1.0-x86_64-unknown-linux-musl.tar.gz|1|ripgrep-*/rg
EOF

# --- Build unified catalog.lock ---
catalog="$specdir/catalog.lock"
tmp="$(mktemp)"

if [ -f "$specdir/apt.manual.versions.txt" ]; then
  awk 'NF>=1{ printf "%s|%s|apt\n",$1, ($2?$2:"") }' "$specdir/apt.manual.versions.txt" >> "$tmp"
fi
if [ -f "$specdir/brew.leaves.versions.txt" ]; then
  awk 'NF>=1{ printf "%s|%s|brew\n",$1, ($2?$2:"") }' "$specdir/brew.leaves.versions.txt" >> "$tmp"
fi

awk -F'|' '
{
  name=$1; ver=$2;
  if (!(name in best) || ver > best[name]) best[name]=ver
}
END{
  for (n in best) printf "%s|%s\n", n, best[n]
}' "$tmp" | sort -f > "$catalog"

rm -f "$tmp"
echo "Wrote $catalog"

echo "Done."

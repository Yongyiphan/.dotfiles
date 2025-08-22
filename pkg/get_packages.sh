#!/usr/bin/env bash
# get_packages.sh — APT/Brew specs + interactive menu
set -euo pipefail

# ---------- helpers ----------
exists(){ command -v "$1" >/dev/null 2>&1; }
human(){ awk 'function H(x,u,i){split("B KB MB GB TB",u);for(i=1;x>=1024&&i<5;i++)x/=1024;printf("%.2f %s",x,u[i])}{H($1)}'; }
ts(){ date +%F_%H%M%S; }
OUT_DIR="${OUT_DIR:-$HOME/pkg-audit}"

# ---------- APT specs ----------
apt_specs() {
  local no_header=0 force_all=0
  local pkgs=()
  while (($#)); do
    case "$1" in
      -N) no_header=1;;
      -A) force_all=1;;
      -h|--help)
        cat <<'EOF'
apt_specs  — print APT package specs as TSV
Usage:
  apt_specs                   # (TTY) shows help; (redirected) dump ALL pkgs
  apt_specs -A                # dump ALL pkgs to terminal
  apt_specs -N                # hide header
  apt_specs <pkg...>          # only these pkgs
Columns:
  PKG  VERSION  ARCH  SIZE_BYTES  SIZE_HUMAN  MANUAL  DEPENDS  RDEPS_COUNT
EOF
        return 0;;
      -*) echo "apt_specs: unknown flag $1" >&2; return 2;;
      *)  pkgs+=("$1");;
    esac; shift
  done

  if ! exists dpkg-query; then
    echo -e "PKG\tVERSION\tARCH\tSIZE_BYTES\tSIZE_HUMAN\tMANUAL\tDEPENDS\tRDEPS_COUNT"
    return 0
  fi

  if [ ${#pkgs[@]} -eq 0 ]; then
    if [ -t 1 ] && (( ! force_all )); then apt_specs --help; return 0; fi
    mapfile -t pkgs < <(dpkg-query -W -f='${Package}\n' | sort)
  fi

  (( no_header == 0 )) && echo -e "PKG\tVERSION\tARCH\tSIZE_BYTES\tSIZE_HUMAN\tMANUAL\tDEPENDS\tRDEPS_COUNT"
  local manual_list; manual_list="$(apt-mark showmanual 2>/dev/null || true)"

  while IFS=$'\t' read -r pkg ver arch size_kb depends; do
    [ -z "${pkg:-}" ] && continue
    local size_b=$(( ${size_kb:-0} * 1024 ))
    local manual=0; grep -qx "$pkg" <<<"$manual_list" && manual=1 || true
    local rdeps
    rdeps=$(apt-cache rdepends --installed "$pkg" 2>/dev/null \
           | awk 'NR>2{print $1}' | grep -v "^'"$pkg"'$" | sort -u | wc -l)
    local hsize; hsize="$(printf "%s\n" "$size_b" | human)"
    echo -e "${pkg}\t${ver}\t${arch}\t${size_b}\t${hsize}\t${manual}\t${depends:-"-"}\t${rdeps}"
  done < <(dpkg-query -W --showformat='${Package}\t${Version}\t${Architecture}\t${Installed-Size}\t${Depends}\n' "${pkgs[@]}")
}

apt_pinlist(){ dpkg-query -W -f='${Package}=${Version}\n' 2>/dev/null | sort; }

# ---------- Brew specs ----------
brew_specs() {
  local no_header=0 force_all=0
  local formulas=()
  while (($#)); do
    case "$1" in
      -N) no_header=1;;
      -A) force_all=1;;
      -h|--help)
        cat <<'EOF'
brew_specs — print Homebrew formula specs as TSV
Usage:
  brew_specs                  # (TTY) shows help; (redirected) dump ALL formulae
  brew_specs -A               # dump ALL formulae to terminal
  brew_specs -N               # hide header
  brew_specs <formula...>     # only these
Columns:
  FORMULA  VERSION  SIZE_BYTES  SIZE_HUMAN  LEAF  DEPS  RDEPS  TAP
EOF
        return 0;;
      -*) echo "brew_specs: unknown flag $1" >&2; return 2;;
      *)  formulas+=("$1");;
    esac; shift
  done

  if ! exists brew; then
    echo -e "FORMULA\tVERSION\tSIZE_BYTES\tSIZE_HUMAN\tLEAF\tDEPS\tRDEPS\tTAP"; return 0
  fi

  local cellar; cellar="$(brew --cellar)"
  if [ ${#formulas[@]} -eq 0 ]; then
    if [ -t 1 ] && (( ! force_all )); then brew_specs --help; return 0; fi
    mapfile -t formulas < <(brew list --formula)
  fi

  (( no_header == 0 )) && echo -e "FORMULA\tVERSION\tSIZE_BYTES\tSIZE_HUMAN\tLEAF\tDEPS\tRDEPS\tTAP"
  local leaves; leaves="$(brew leaves 2>/dev/null || true)"
  for f in "${formulas[@]}"; do
    local ver bytes hsize leaf deps rdeps tap
    ver="$(brew list --versions "$f" | awk '{print $2}')"
    bytes="$(du -sb "$cellar/$f"/* 2>/dev/null | awk '{s+=$1} END{print s+0}')"
    hsize="$(printf "%s\n" "${bytes:-0}" | human)"
    leaf=0; grep -qx "$f" <<<"$leaves" && leaf=1 || true
    deps="$(brew deps --formula "$f" 2>/dev/null | paste -sd, -)"
    rdeps="$(brew uses --installed "$f" 2>/dev/null | paste -sd, -)"
    if exists jq; then
      tap="$(brew info --json=v2 "$f" | jq -r '.formulae[0].tap // "-"')"
    else
      tap="$(brew info "$f" | awk -F'/' '/^From: /{print $(NF-1)"/"$NF; exit}')" || tap="-"
      [ -z "$tap" ] && tap="-"
    fi
    echo -e "${f}\t${ver:-"-"}\t${bytes:-0}\t${hsize}\t${leaf}\t${deps:-"-"}\t${rdeps:-"-"}\t${tap}"
  done
}

brew_versionlist(){ brew list --versions 2>/dev/null | awk '{print $1"="$2}' | sort; }

# ---------- duplicates (name match) ----------
apt_brew_duplicates() {
  exists dpkg-query && dpkg-query -W -f='${Package}\n' | sort > /tmp/_apt_pkgs.$$ || : > /tmp/_apt_pkgs.$$
  exists brew && brew list --formula | sort > /tmp/_brew_fml.$$ || : > /tmp/_brew_fml.$$
  echo -e "NAME\tIN_APT\tIN_BREW"
  comm -12 /tmp/_apt_pkgs.$$ /tmp/_brew_fml.$$ | awk '{print $1"\t1\t1"}'
  rm -f /tmp/_apt_pkgs.$$ /tmp/_brew_fml.$$
}

# ---------- menu ----------
gp_menu() {
  mkdir -p "$OUT_DIR"
  while true; do
    echo
    echo "== Package Audit Menu =="
    echo "1) Dump APT specs (TSV) -> $OUT_DIR/apt_specs_$(ts).tsv"
    echo "2) Dump Brew specs (TSV) -> $OUT_DIR/brew_specs_$(ts).tsv"
    echo "3) Dump BOTH (APT + Brew)"
    echo "4) List APT↔Brew duplicates (name match)"
    echo "5) APT top 30 by size (terminal view)"
    echo "6) Brew top 30 by size (terminal view)"
    echo "7) Write APT pinlist (pkg=ver) -> $OUT_DIR/apt_versions_$(ts).txt"
    echo "8) Write Brew version list -> $OUT_DIR/brew_versions_$(ts).txt"
    echo "9) Quit"
    read -rp "Select: " ch
    case "$ch" in
      1)
        f="$OUT_DIR/apt_specs_$(ts).tsv"
        apt_specs -A > "$f"
        echo "Wrote $f"
        ;;
      2)
        f="$OUT_DIR/brew_specs_$(ts).tsv"
        brew_specs -A > "$f"
        echo "Wrote $f"
        ;;
      3)
        f1="$OUT_DIR/apt_specs_$(ts).tsv"; f2="$OUT_DIR/brew_specs_$(ts).tsv"
        apt_specs -A > "$f1"; brew_specs -A > "$f2"
        echo "Wrote $f1"; echo "Wrote $f2"
        ;;
      4)
        apt_brew_duplicates | column -t -s $'\t'
        ;;
      5)
        if exists dpkg-query; then
          dpkg-query -W --showformat='${Installed-Size}\t${Package}\n' \
          | sort -n | tail -n 30 \
          | awk '{printf "%10s\t%s\n", $1" KB",$2}' | column -t
        else echo "APT not found"; fi
        ;;
      6)
        if exists brew; then
          CELLAR="$(brew --cellar)"
          du -sb "$CELLAR"/*/* 2>/dev/null | sort -n | tail -n 30 \
          | awk '{print $1}' | human | paste -d'\t' - <(du -sb "$CELLAR"/*/* 2>/dev/null | sort -n | tail -n 30 | awk -F/ '{print $(NF-1)}') \
          | column -t
        else echo "Brew not found"; fi
        ;;
      7)
        f="$OUT_DIR/apt_versions_$(ts).txt"
        apt_pinlist > "$f" || true
        echo "Wrote $f"
        ;;
      8)
        f="$OUT_DIR/brew_versions_$(ts).txt"
        brew_versionlist > "$f" || true
        echo "Wrote $f"
        ;;
      9) break;;
      *) echo "Invalid choice";;
    esac
  done
}

# ---------- aliases (only when sourced) ----------
__gp_install_aliases() {
  alias aps='apt_specs -A'
  alias apsn='apt_specs -A -N'
  alias apv='apt_pinlist'
  alias bws='brew_specs -A'
  alias bwsn='brew_specs -A -N'
  alias bwv='brew_versionlist'
  apsx(){ apt_specs -A "$@" | column -t -s $'\t'; }
  bwsx(){ brew_specs -A "$@" | column -t -s $'\t'; }
  apdump(){ mkdir -p "$OUT_DIR"; apt_specs -A > "$OUT_DIR/apt_specs_$(ts).tsv"; echo "Wrote $OUT_DIR/apt_specs_$(ts).tsv"; }
  bwdump(){ mkdir -p "$OUT_DIR"; brew_specs -A > "$OUT_DIR/brew_specs_$(ts).tsv"; echo "Wrote $OUT_DIR/brew_specs_$(ts).tsv"; }
  alias gp='bash ~/.local/bin/get_packages.sh'  # quick menu launcher
  [ "${GP_SILENT:-0}" = "1" ] || echo "Loaded: aps/apsx/apv, bws/bwsx/bwv, apdump/bwdump, gp"
}

# Detect sourced vs executed
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  __gp_install_aliases
else
  gp_menu
fi

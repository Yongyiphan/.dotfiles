#!/bin/bash
# install.sh — install from a specs directory and/or catalog.lock
#
# Usage examples:
#   ./install.sh --spec-dir profile/EdgarPC_ubuntu/specs              # dry-run
#   ./install.sh --spec-dir profile/EdgarPC_ubuntu/specs --yes        # do it
#   ./install.sh -f catalog.lock --yes
#   ./install.sh --spec-dir DIR --priority apt,brew,tar --yes
#
# Recognized files inside --spec-dir:
#   catalog.lock                  # lines: pkg | pkg=ver | apt:... | brew:... | tar:... [url=...]
#   apt.manual.versions.txt       # lines: "<pkg> <version>"
#   brew.leaves.versions.txt      # lines: "<formula> <version>"
#   tarball.specs                 # lines (any of):
#                                 #   name=ver url=...
#                                 #   name ver url=...
#                                 #   name=ver
#                                 #   name
#
# Notes:
# - Default priority: apt,tar,brew (change with --priority).
# - APT: attempts exact "pkg=version" first, falls back to unversioned if that pin isn’t available.
# - BREW: installs latest if exact version tap/formula isn’t available.
# - TAR: extracts into --prefix (default ~/.local); looks in --tar-dir if no url=.

set -euo pipefail

DO_IT="no"
SPEC_DIR=""
LOCK_FILE=""
PREFIX="${HOME}/.local"
TAR_DIR="${HOME}/.local/share/pkgs"
CACHE_DIR="${HOME}/.cache/install"
PRIORITY="apt,tar,brew"

log(){ printf "\033[1;34m[install]\033[0m %s\n" "$*" >&2; }
warn(){ printf "\033[1;33m[warn]\033[0m %s\n" "$*" >&2; }
err(){ printf "\033[1;31m[error]\033[0m %s\n" "$*" >&2; }
run(){ if [ "$DO_IT" = "yes" ]; then log "exec: $*"; eval "$@"; else log "dry-run: $*"; fi; }
need(){ command -v "$1" >/dev/null 2>&1; }
is_debian(){ [ -e /etc/debian_version ]; }

ensure_dirs(){ mkdir -p "$PREFIX" "$TAR_DIR" "$CACHE_DIR"; }

# ---------- APT ----------
APT_UPDATED="no"
apt_update_once(){ [ "$APT_UPDATED" = "yes" ] && return; need apt-get || return; run "[ \"$(id -u)\" -ne 0 ] && sudo apt-get update -y || apt-get update -y"; APT_UPDATED="yes"; }
apt_installed(){ need dpkg-query || return 1; dpkg-query -W -f='${Status}\n' "$1" 2>/dev/null | grep -q "install ok installed"; }
apt_install(){
  local pkg="$1" ver="${2:-}"
  need apt-get || return 1
  apt_update_once
  if [ -n "$ver" ]; then
    run "[ \"$(id -u)\" -ne 0 ] && sudo apt-get install -y ${pkg}=${ver} || apt-get install -y ${pkg}=${ver}" \
    || { warn "apt exact pin failed for ${pkg}=${ver}, trying latest"; run "[ \"$(id -u)\" -ne 0 ] && sudo apt-get install -y ${pkg} || apt-get install -y ${pkg}"; }
  else
    run "[ \"$(id -u)\" -ne 0 ] && sudo apt-get install -y ${pkg} || apt-get install -y ${pkg}"
  fi
}

# ---------- BREW ----------
brew_installed(){ need brew || return 1; brew list --versions "$1" >/dev/null 2>&1; }
brew_install(){
  local pkg="$1" ver="${2:-}"
  need brew || return 1
  # Try formula@MAJOR or @MAJOR.MINOR if available, else latest
  if [ -n "$ver" ]; then
    local major="${ver%%.*}"
    if brew info "${pkg}@${major}" >/dev/null 2>&1; then
      run "brew install ${pkg}@${major}"
      return 0
    fi
    # fall back:
    warn "brew: ${pkg}@${major} not found; installing latest '${pkg}'"
  fi
  run "brew install ${pkg}"
}

# ---------- TAR ----------
tar_from_file(){
  local tarball="$1" dest="$2"
  [ -f "$tarball" ] || { err "tarball not found: $tarball"; return 1; }
  run "mkdir -p '$dest'"
  run "tar -xf '$tarball' -C '$dest'"
}
tar_from_url(){
  local url="$1" stem="$2"
  local out="$CACHE_DIR/${stem}.tar"
  run "mkdir -p '$CACHE_DIR'"
  if [ "$DO_IT" = "yes" ]; then curl --fail --location --silent --show-error -o "${out}.tmp" "$url"; mv "${out}.tmp" "$out"; else log "dry-run: curl -fsSL -o '${out}.tmp' '$url' && mv"; fi
  tar_from_file "$out" "$PREFIX"
}
tar_install(){
  local name="$1" ver="${2:-}" url="${3:-}"
  local stem="${name}${ver:+-$ver}"
  if [ -n "$url" ]; then tar_from_url "$url" "$stem"; return; fi
  local f
  for f in \
    "$TAR_DIR/${stem}.tar.gz" "$TAR_DIR/${stem}.tgz" "$TAR_DIR/${stem}.tar.xz" "$TAR_DIR/${stem}.tar.zst" "$TAR_DIR/${stem}.tar" \
    "$TAR_DIR/${name}.tar.gz" "$TAR_DIR/${name}.tgz" "$TAR_DIR/${name}.tar.xz" "$TAR_DIR/${name}.tar.zst" "$TAR_DIR/${name}.tar"
  do [ -f "$f" ] && { tar_from_file "$f" "$PREFIX"; return; }; done
  err "No tarball for '$name' ${ver:+(ver $ver)} and no url= provided"
  return 1
}

# ---------- Priority driver ----------
try_install_in_order(){
  local pkg="$1" ver="$2" url="$3" IFS=, order
  read -r -a order <<< "$PRIORITY"
  for m in "${order[@]}"; do
    case "$m" in
      apt)  need apt-get && { apt_install "$pkg" "$ver" && return 0; } ;;
      tar)  tar_install "$pkg" "$ver" "$url" && return 0 ;;
      brew) need brew && { brew_install "$pkg" "$ver" && return 0; } ;;
      *) warn "Unknown method in priority: $m";;
    esac
  done
  return 1
}

# ---------- Parsers ----------
parse_lock_line(){
  # echo "<src> <pkg> <ver> <url>"; src ∈ {apt,brew,tar,auto}
  local line="$1"; line="${line%%#*}"; line="$(echo "$line" | xargs)"; [ -z "$line" ] && return 1
  local src="auto" item ver="" url=""
  [[ "$line" == apt:*  ]] && src="apt"  && line="${line#apt:}"
  [[ "$line" == brew:* ]] && src="brew" && line="${line#brew:}"
  [[ "$line" == tar:*  ]] && src="tar"  && line="${line#tar:}"
  if [[ "$line" =~ url=(.+)$ ]]; then url="${BASH_REMATCH[1]}"; line="$(echo "$line" | sed -E 's/[[:space:]]*url=.*$//')"; line="$(echo "$line" | xargs)"; fi
  if [[ "$src" == "brew" && "$line" == *@* ]]; then item="${line%@*}"; ver="${line#*@}"; echo "$src $item $ver $url"; return 0; fi
  if [[ "$line" == *"="* ]]; then item="${line%%=*}"; ver="${line#*=}"; else item="$line"; fi
  echo "$src $item $ver $url"
}

# apt.manual.versions.txt: "<pkg> <version>"
process_apt_manual_versions(){
  local f="$1" pkg ver
  [ -f "$f" ] || return 0
  log "-- APT manual versions: $f"
  while read -r pkg ver _; do
    [[ -z "${pkg:-}" || "${pkg:0:1}" = "#" ]] && continue
    if is_debian && apt_installed "$pkg"; then log "skip (installed): $pkg"; continue; fi
    apt_install "$pkg" "$ver" || warn "APT failed: $pkg $ver"
  done < "$f"
}

# brew.leaves.versions.txt: "<formula> <version>"
process_brew_leaves_versions(){
  local f="$1" fm ver
  [ -f "$f" ] || return 0
  log "-- Brew leaves: $f"
  while read -r fm ver _; do
    [[ -z "${fm:-}" || "${fm:0:1}" = "#" ]] && continue
    brew_installed "$fm" && { log "skip (installed): $fm"; continue; } || true
    brew_install "$fm" "$ver" || warn "Brew failed: $fm $ver"
  done < "$f"
}

# tarball.specs: flexible (name[/=]ver [url=...])
process_tarball_specs(){
  local f="$1" line name ver url
  [ -f "$f" ] || return 0
  log "-- Tarball specs: $f"
  while read -r line; do
    line="${line%%#*}"; line="$(echo "$line" | xargs)"; [ -z "$line" ] && continue
    url=""
    if [[ "$line" =~ url=(.+)$ ]]; then url="${BASHREMATCH[1]}"; line="$(echo "$line" | sed -E 's/[[:space:]]*url=.*$//')"; line="$(echo "$line" | xargs)"; fi
    if [[ "$line" == *"="* ]]; then name="${line%%=*}"; ver="${line#*=}"
    else read -r name ver <<<"$line"; ver="${ver:-}"; fi
    tar_install "$name" "$ver" "$url" || warn "TAR failed: $name ${ver:-}"
  done < "$f"
}

# catalog.lock (mixed)
process_catalog_lock(){
  local f="$1" parsed src pkg ver url
  [ -f "$f" ] || return 0
  log "-- Catalog lock: $f"
  while read -r raw; do
    [[ -z "${raw// }" || "${raw#\#}" != "$raw" ]] && continue
    parsed="$(parse_lock_line "$raw")" || { warn "skip unparsable: $raw"; continue; }
    set -- $parsed; src="$1"; pkg="$2"; ver="${3:-}"; url="${4:-}"
    [ -z "$pkg" ] && { warn "skip empty pkg line"; continue; }

    # short-circuit if present
    if is_debian && apt_installed "$pkg"; then log "skip (installed): $pkg"; continue; fi
    if need brew && brew_installed "$pkg"; then log "skip (installed via brew): $pkg"; continue; fi
    if command -v "$pkg" >/dev/null 2>&1; then log "skip (in PATH): $pkg"; continue; fi

    case "$src" in
      apt)  apt_install "$pkg" "$ver" || warn "APT failed: $pkg $ver" ;;
      brew) brew_install "$pkg" "$ver" || warn "Brew failed: $pkg $ver" ;;
      tar)  tar_install "$pkg" "$ver" "$url" || warn "TAR failed: $pkg $ver" ;;
      auto) try_install_in_order "$pkg" "$ver" "$url" || warn "Auto failed: $pkg $ver" ;;
    esac
  done < "$f"
}

# ---------- args ----------
while [ $# -gt 0 ]; do
  case "$1" in
    --spec-dir) SPEC_DIR="${2:-}"; shift 2;;
    -f|--file)  LOCK_FILE="${2:-}"; shift 2;;
    --prefix)   PREFIX="${2:-}"; shift 2;;
    --tar-dir)  TAR_DIR="${2:-}"; shift 2;;
    --priority) PRIORITY="${2:-}"; shift 2;;
    -y|--yes)   DO_IT="yes"; shift;;
    -h|--help)  sed -n '1,140p' "$0" | sed 's/^# //;t;d'; exit 0;;
    *) err "Unknown arg: $1"; exit 2;;
  esac
done

ensure_dirs

# Discover files in SPEC_DIR (if given)
APT_FILE=""; BREW_FILE=""; TARBALL_FILE=""
if [ -n "$SPEC_DIR" ]; then
  [ -f "$SPEC_DIR/catalog.lock" ]             && LOCK_FILE="$SPEC_DIR/catalog.lock"
  [ -f "$SPEC_DIR/apt.manual.versions.txt" ]  && APT_FILE="$SPEC_DIR/apt.manual.versions.txt"
  [ -f "$SPEC_DIR/brew.leaves.versions.txt" ] && BREW_FILE="$SPEC_DIR/brew.leaves.versions.txt"
  [ -f "$SPEC_DIR/tarball.specs" ]            && TARBALL_FILE="$SPEC_DIR/tarball.specs"
fi

log "Mode: ${DO_IT^^} | Priority: $PRIORITY"
[ -n "$SPEC_DIR" ] && log "Spec dir: $SPEC_DIR"
[ -n "$LOCK_FILE" ] && log "catalog.lock: $LOCK_FILE"
[ -n "$APT_FILE" ] && log "apt.manual.versions.txt: $APT_FILE"
[ -n "$BREW_FILE" ] && log "brew.leaves.versions.txt: $BREW_FILE"
[ -n "$TARBALL_FILE" ] && log "tarball.specs: $TARBALL_FILE"

# Process in logical order
[ -n "$LOCK_FILE" ]   && process_catalog_lock "$LOCK_FILE"
[ -n "$APT_FILE" ]    && process_apt_manual_versions "$APT_FILE"
[ -n "$TARBALL_FILE" ]&& process_tarball_specs "$TARBALL_FILE"
[ -n "$BREW_FILE" ]   && process_brew_leaves_versions "$BREW_FILE"

log "Done."

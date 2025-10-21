#!/usr/bin/env bash
# ~/.dotfiles/scripts/load-env.sh
# Profiles are directories under ~/.dotfiles/profiles/<PROFILE>/ENV

# --- resolve repo root ---
_dotfiles_root() {
  local here="${BASH_SOURCE[0]}"
  while [ -L "$here" ]; do here="$(readlink "$here")"; done
  cd "$(dirname "$here")/.." >/dev/null 2>&1 && pwd
}
: "${DOTFILES_ROOT:="$(_dotfiles_root)"}"

# profiles dir (plural preferred; fall back to legacy singular)
_PROFILES_DIR="$DOTFILES_ROOT/profiles"
[ -d "$_PROFILES_DIR" ] || _PROFILES_DIR="$DOTFILES_ROOT/profile"

# --- optionally import OS facts (harmless if absent) ---
if [ -z "${OS_TYPE-}" ] && [ -f "$DOTFILES_ROOT/scripts/detect-os.sh" ]; then
  # shellcheck source=/dev/null
  . "$DOTFILES_ROOT/scripts/detect-os.sh"
fi

# --- choose a profile ---
# priority:
# 1) explicit arg
# 2) $DOTFILES_PROFILE
# 3) profiles/current symlink/dir
# 4) exact <hostname>_<distro_id> (e.g., EdgarPC_ubuntu)
# 5) exact <hostname>
# 6) hostname prefix match
# 7) single dir
# 8) error
_dot_detect_profile() {
  local arg="$1" dir="$_PROFILES_DIR"
  [ -d "$dir" ] || { echo "dotfiles: profiles directory not found: $dir" >&2; return 1; }

  # 1) explicit arg
  [ -n "${arg:-}" ] && { echo "$arg"; return; }

  # 2) env var
  [ -n "${DOTFILES_PROFILE:-}" ] && { echo "$DOTFILES_PROFILE"; return; }

  # 3) current selector
  [ -e "$dir/current" ] && { echo "current"; return; }

  # host + distro facts
  local host distro_id short
  short="$(hostname -s 2>/dev/null || hostname)"
  host="$short"
  if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    distro_id="$(printf '%s' "${ID:-unknown}" | tr '[:upper:]' '[:lower:]')"
  else
    distro_id="unknown"
  fi

  # 4) exact "<host>_<distro_id>"
  if [ -d "$dir/${host}_${distro_id}" ]; then
    echo "${host}_${distro_id}"; return;
  fi

  # 5) exact "<host>"
  if [ -d "$dir/$host" ]; then
    echo "$host"; return
  fi

  # 6) prefix match "<host>*"
  if compgen -G "$dir/${host}*" >/dev/null; then
    basename -- "$(ls -1d "$dir/${host}"* 2>/dev/null | head -n1)"
    return
  fi

  # 7) single dir present
  mapfile -t _pros < <(find "$dir" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null)
  if [ "${#_pros[@]}" -eq 1 ]; then
    echo "${_pros[0]}"; return
  fi

  # 8) cannot decide
  echo "dotfiles: cannot determine profile in $dir. Available:" >&2
  printf '  - %s\n' "${_pros[@]}" >&2
  return 1
}

# path helper
dot_env_path() {
  local p; p="$(_dot_detect_profile "${1:-}")" || return 1
  echo "$_PROFILES_DIR/$p/ENV"
}

# loader
dot_load_env() {
  local profile env_file
  profile="$(_dot_detect_profile "${1:-}")" || return 1
  env_file="$_PROFILES_DIR/$profile/ENV"
  [ -f "$env_file" ] || { echo "ENV not found: $env_file" >&2; return 1; }
  set -a
  # shellcheck source=/dev/null
  . "$env_file"
  set +a
  export DOTFILES_PROFILE="$profile"
}

# if executed directly: load and report
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  if dot_load_env "${1:-}"; then
    echo "Loaded: $DOTFILES_PROFILE"
    echo "ENV: $(dot_env_path "$DOTFILES_PROFILE")"
  else
    exit 1
  fi
fi


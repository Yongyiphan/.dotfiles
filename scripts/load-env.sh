#!/usr/bin/env bash
# ~/.dotfiles/scripts/load-env.sh
# Strict loader: pick the profile from lib/profile.sh:get_profile_name()
# (or explicit arg / valid DOTFILES_PROFILE), then source its ENV.
# No legacy fallbacks, no auto-creation.

# --- resolve repo root (follow symlinks) ---
_dotfiles_root() {
  local here="${BASH_SOURCE[0]}"
  while [ -L "$here" ]; do here="$(readlink "$here")"; done
  cd "$(dirname "$here")/.." >/dev/null 2>&1 && pwd
}
: "${DOTFILES_ROOT:="$(_dotfiles_root)"}"

# --- choose canonical base dir (prefer 'profiles/', fall back to 'profile/') ---
PROFILES_BASE="$DOTFILES_ROOT/profiles"
[ -d "$PROFILES_BASE" ] || PROFILES_BASE="$DOTFILES_ROOT/profiles"

# --- make sure get_profile_name() exists (force-load common locations) ---
for _f in \
  "$DOTFILES_ROOT/lib/profile.sh" 
do
  [ -f "$_f" ] && . "$_f"
done

if ! declare -F get_profile_name >/dev/null 2>&1; then
  echo "load-env: get_profile_name() not available; expected in lib/profile.sh" >&2
  return 1
fi

# --- internal: resolve the intended profile name ---
# Priority:
#  1) explicit arg (must exist)
#  2) DOTFILES_PROFILE (must exist)
#  3) get_profile_name()
_dot_profile_name() {
  local want="$1"

  if [ -n "$want" ]; then
    if [ -d "$PROFILES_BASE/$want" ]; then printf '%s\n' "$want"; return 0; fi
    echo "load-env: explicit profile '$want' not found under $PROFILES_BASE" >&2
    return 1
  fi

  if [ -n "${DOTFILES_PROFILE:-}" ]; then
    if [ -d "$PROFILES_BASE/$DOTFILES_PROFILE" ]; then printf '%s\n' "$DOTFILES_PROFILE"; return 0; fi
    echo "load-env: DOTFILES_PROFILE='$DOTFILES_PROFILE' does not exist under $PROFILES_BASE" >&2
    # do NOT return here; fall through to computed name
  fi

  get_profile_name
}

# --- public: echo path to ENV for a given/active profile ---
dot_env_path() {
  local name; name="$(_dot_profile_name "${1:-}")" || return 1
  printf '%s/%s/ENV\n' "$PROFILES_BASE" "$name"
}

# --- public: load ENV for a given/active profile (strict) ---
dot_load_env() {
  local name env_file
  name="$(_dot_profile_name "${1:-}")" || return 1
	echo $name
  env_file="$PROFILES_BASE/$name/ENV"

  if [ ! -f "$env_file" ]; then
    echo "load-env: ENV not found: $env_file" >&2
    echo "hint: create it or choose another profile (arg or DOTFILES_PROFILE)" >&2
    return 1
  fi

  set -a
  # shellcheck source=/dev/null
  . "$env_file"
  set +a

	echo Loaded: $env_file
  export DOTFILES_PROFILE="$name"
}

# --- if executed directly, try to load and report ---
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  if dot_load_env "${1:-}"; then
    echo "Loaded profile: $DOTFILES_PROFILE"
    echo "ENV: $(dot_env_path "$DOTFILES_PROFILE")"
  else
    exit 1
  fi
fi


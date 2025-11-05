#!/usr/bin/env bash

# Guard so multiple sources are harmless
[ -n "${_PROFILE_SH:-}" ] && return 0; _PROFILE_SH=1

_dotf_sanitize() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]_-' '_'; }

get_profile_name() {
  local host user distro 
	local mid=""
  host="$(hostnamectl --static 2>/dev/null || hostname -s 2>/dev/null || uname -n)"
  user="$(id -un 2>/dev/null || echo "${USER:-unknown}")"
  if [ -r /etc/os-release ]; then . /etc/os-release; distro="${ID:-linux}"; else distro="unknown"; fi
  [ -n "${WSL_DISTRO_NAME:-}" ] && distro="${distro}-wsl"

  # OPT-IN suffix (default OFF)
  # if [ "${USE_MACHINE_ID:-0}" = "1" ] && [ -r /etc/machine-id ]; then
  #   mid="_$(head -c8 /etc/machine-id)"
  # fi

  printf '%s_%s_%s%s\n' "$(_dotf_sanitize "$host")" "$(_dotf_sanitize "$user")" "$(_dotf_sanitize "$distro")" "$mid"
}

init_profile_env() {
  : "${DOTFILES:=$HOME/.dotfiles}"
  export PROFILE_NAME="${PROFILE_NAME:-$(get_profile_name)}"
  export PROFILE_DIR="${DOTFILES}/profiles/${PROFILE_NAME}"
  export SPEC_DIR="${PROFILE_DIR}/specs"
  mkdir -p "$SPEC_DIR"
}

# If run directly, just print name (optional)
if [ "${BASH_SOURCE:-$0}" = "$0" ]; then
	get_profile_name
fi


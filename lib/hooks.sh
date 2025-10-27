# Guard
[ -n "${_DOT_HOOKS_SH:-}" ] && return 0; _DOT_HOOKS_SH=1
dot_profile_dir() {
  : "${DOTFILES:=$HOME/.dotfiles}"
  : "${DOTFILES_PROFILE:?DOTFILES_PROFILE not set}"
  printf '%s/profiles/%s\n' "$DOTFILES" "$DOTFILES_PROFILE"
}
dot_profile_hook() {
  local name="$1" dir f
  [ -n "$name" ] || return 1
  dir="$(dot_profile_dir)" || return 1
  f="$dir/$name.sh"
  [ -f "$f" ] && . "$f"  # shellcheck source=/dev/null
  if [ -d "$dir/$name.d" ]; then
    for f in "$dir/$name.d/"*.sh; do
      [ -e "$f" ] || continue
      . "$f"     # shellcheck source=/dev/null
    done
  fi
}


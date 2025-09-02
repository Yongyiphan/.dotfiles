#!/bin/bash


# List symlinks on the system (or specific roots)
# Usage:
#   list_symlinks                     # scan whole OS (skips /proc,/sys,/dev,/run,/snap)
#   list_symlinks --roots "$HOME"     # scan only $HOME
#   list_symlinks --roots "$HOME" "$HOME/.config" "$HOME/.local/bin"
#   list_symlinks --dotfiles-only     # only links pointing into $DOTFILES or $DOTFILES/home
#   list_symlinks --broken-only       # only dangling/broken links
#   list_symlinks -h|--help
list_symlinks() {
  local roots=() dotonly=0 brokenonly=0
  local DF="${DOTFILES:-$HOME/.dotfiles}"
  local DFH="${DOTFILES_HOME:-$DF/home}"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --roots) shift; while [[ $# -gt 0 && "$1" != --* ]]; do roots+=("$1"); shift; done; continue ;;
      --dotfiles-only) dotonly=1 ;;
      --broken-only) brokenonly=1 ;;
      -h|--help)
        cat <<'EOF'
list_symlinks [--roots <dir> [dir...]] [--dotfiles-only] [--broken-only]
  --roots DIR ...   Scan only these roots (repeatable). Default: whole OS (prunes /proc,/sys,/dev,/run,/snap).
  --dotfiles-only   Show only links whose targets live under $DOTFILES or $DOTFILES/home.
  --broken-only     Show only dangling symlinks.
EOF
        return 0
        ;;
      *) roots+=("$1") ;;
    esac
    shift
  done

  # Default: scan the whole OS, but prune noisy pseudo-fs
  if ((${#roots[@]}==0)); then
    roots=(/ )
  fi

  # Build the find command with prunes for common ephemeral mounts
  # shellcheck disable=SC2016
  find "${roots[@]}" \
    \( -path /proc -o -path /sys -o -path /dev -o -path /run -o -path /snap \) -prune -o \
    -type l -print0 2>/dev/null \
  | while IFS= read -r -d '' L; do
      # target as written + resolved absolute (if possible)
      local T A status=""
      T="$(readlink "$L" 2>/dev/null || true)"
      A="$(readlink -f "$L" 2>/dev/null || true)"

      # broken if resolved target doesn't exist
      local is_broken=0
      [[ -n "$A" && ! -e "$A" ]] && is_broken=1
      [[ -z "$A" && -n "$T" ]] && is_broken=1  # dangling to relative that can't resolve

      # filter: dotfiles-managed only
      if ((dotonly)); then
        case "$A" in
          "$DF"/*|"$DFH"/*) : ;;
          *) continue ;;
        esac
      fi

      # filter: broken-only
      ((brokenonly)) && ((is_broken==0)) && continue

      ((is_broken)) && status=" [BROKEN]"
      printf '%s -> %s%s\n' "$L" "${T:-<dangling>}" "$status"
    done | sort
}

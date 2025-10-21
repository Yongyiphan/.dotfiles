#!/bin/bash

enable_file(){
  [ $# -eq 1 ] || { echo "Error: pass a file or directory"; return 1; }
  local p="$1"
  if [ -d "$p" ]; then
    find "$p" -maxdepth 1 -type f -name '*.sh' -print0 \
    | while IFS= read -r -d '' f; do
        chmod +x -- "$f"
        echo "File '$f' is now executable."
      done
    return 0
  fi
  if [ -f "$p" ]; then
    chmod +x -- "$p"
    echo "File '$p' is now executable."
  else
    echo "Error: '$p' does not exist."
    return 1
  fi
}

goto() {
  local q="${1:-}"; [[ -z "$q" ]] && { echo "usage: goto <name-fragment>"; return 2; }

  # shortcut map
  if declare -p gotoPaths &>/dev/null && [[ -n "${gotoPaths[$q]:-}" ]]; then
    cd -- "${gotoPaths[$q]}" || return; return 0
  fi

  # backends
  local SEARCH_BACKEND="" FD_BIN=""
  if command -v fd >/dev/null 2>&1; then FD_BIN="fd"; SEARCH_BACKEND="fd"
  elif command -v fdfind >/dev/null 2>&1; then FD_BIN="fdfind"; SEARCH_BACKEND="fd"
  elif command -v find >/dev/null 2>&1; then SEARCH_BACKEND="find"
  else echo "goto: need a search tool (install fd or ensure 'find' exists)."; return 1
  fi
  local HAS_FZF=0; command -v fzf >/dev/null 2>&1 && HAS_FZF=1

  # roots (ENV first; else smart defaults)
  local roots_conf="${GOTO_ROOTS:-}"
  if [[ -z "$roots_conf" ]]; then
    if [[ "${IS_WSL:-0}" == "1" ]] && [[ -d /mnt/c/Users ]]; then
      roots_conf="/mnt/c/Users/*/Documents:$HOME"
    elif [[ "${OS_TYPE:-$(uname -s | tr '[:upper:]' '[:lower:]')}" =~ linux ]]; then
      # keep it simple: $HOME only (you can add others in your ENV per device)
      roots_conf="$HOME"
    elif [[ "${OS_TYPE:-}" == "darwin" ]] || [[ "$(uname -s)" == "Darwin" ]]; then
      roots_conf="$HOME"
    else
      roots_conf="$HOME"
    fi
  fi

  # expand colon-separated globs -> concrete dirs
  local -a all_matches=() roots=()
  IFS=':' read -r -a _pats <<< "$roots_conf"
  for pat in "${_pats[@]}"; do
    pat="${pat//\~/$HOME}"; pat="$(eval "printf '%s' \"$pat\"")"
    while IFS= read -r m; do all_matches+=("$m"); done < <(compgen -G "$pat" || true)
    [[ ${#all_matches[@]} -eq 0 && -d "$pat" ]] && all_matches+=("$pat")
  done

  # normalize -> absolute (readlink -f) and dedup
  declare -A seen=()
  for d in "${all_matches[@]}"; do
    [[ -d "$d" && -r "$d" ]] || continue
    local canon; canon="$(readlink -f -- "$d" 2>/dev/null || realpath -m -- "$d" 2>/dev/null || printf '%s' "$d")"
    canon="${canon%/}"
    [[ -z "${seen[$canon]:-}" ]] && { roots+=("$canon"); seen[$canon]=1; }
  done
  # prune sub-roots (remove any root that is a subdir of another root)
  if ((${#roots[@]} > 1)); then
    IFS=$'\n' roots=($(printf '%s\n' "${roots[@]}" | awk '{print length, $0}' | sort -n | cut -d" " -f2-))
    declare -a pruned=()
    for r in "${roots[@]}"; do
      local is_sub=0
      for p in "${pruned[@]}"; do
        [[ "$r" == "$p" ]] && { is_sub=1; break; }
        [[ "$r" == "$p/"* ]] && { is_sub=1; break; }
      done
      (( ! is_sub )) && pruned+=("$r")
    done
    roots=("${pruned[@]}")
  fi
  ((${#roots[@]})) || { echo "goto: no valid roots from '$roots_conf'"; return 1; }

  local ignore_file="${GOTO_IGNORE_FILE:-$HOME/.config/.bash_find_ignore}"
  [[ -f "$ignore_file" ]] || ignore_file=/dev/null

  # search
  declare -A seen_hit=()
  local -a hits=()
  if [[ "$SEARCH_BACKEND" == "fd" ]]; then
    for r in "${roots[@]}"; do
      while IFS= read -r line; do
        local canon; canon="$(readlink -f -- "$line" 2>/dev/null || realpath -m -- "$line" 2>/dev/null || printf '%s' "$line")"
        canon="${canon%/}"
        [[ -z "${seen_hit[$canon]:-}" ]] && { hits+=("$canon"); seen_hit[$canon]=1; }
      done < <("$FD_BIN" -a --type d --ignore-file "$ignore_file" --fixed-strings "$q" "$r" 2>/dev/null || true)
    done
  else
    for r in "${roots[@]}"; do
      while IFS= read -r line; do
        local canon; canon="$(readlink -f -- "$line" 2>/dev/null || realpath -m -- "$line" 2>/dev/null || printf '%s' "$line")"
        canon="${canon%/}"
        [[ -z "${seen_hit[$canon]:-}" ]] && { hits+=("$canon"); seen_hit[$canon]=1; }
      done < <(find "$r" -type d -iname "*$q*" 2>/dev/null || true)
    done
  fi
  ((${#hits[@]})) || { echo "No match for '$q' under configured roots."; return 1; }

  # pick
  local sel=""
  if (( HAS_FZF )); then
    sel="$(printf '%s\n' "${hits[@]}" | fzf --query="$q" --select-1 --exit-0)" || return 1
  else
    if ((${#hits[@]} == 1)); then
      sel="${hits[0]}"
    elif [[ -t 0 && -t 1 ]]; then
      local i=1; for h in "${hits[@]}"; do printf '%2d) %s\n' "$i" "$h"; ((i++)); done
      local pick; read -rp "Choose [1-${#hits[@]}] (0=cancel): " pick
      [[ "$pick" =~ ^[0-9]+$ ]] || { echo "Invalid."; return 1; }
      (( pick>=1 && pick<=${#hits[@]} )) || { echo "Cancelled."; return 1; }
      sel="${hits[pick-1]}"
    else
      [[ "${GOTO_ALLOW_FIRST_NONINTERACTIVE:-1}" == "1" ]] || { printf '%s\n' "${hits[@]}"; return 1; }
      sel="${hits[0]}"
    fi
  fi

  [[ -n "$sel" ]] || { echo "No selection."; return 1; }
  cd -- "$sel" || return
}


# ---------- tiny utils ----------
# define only if not already defined (so callers can override)
command -v exists >/dev/null 2>&1 || exists(){ command -v "$1" >/dev/null 2>&1; }
command -v ts     >/dev/null 2>&1 || ts(){ date +%F_%H%M%S; }
command -v human  >/dev/null 2>&1 || human(){ awk 'function H(x,u,i){split("B KB MB GB TB",u);for(i=1;x>=1024&&i<5;i++)x/=1024;printf("%.2f %s",x,u[i])}{H($1)}'; }
command -v info   >/dev/null 2>&1 || info(){ printf '[%s] %s\n' "${SCRIPT_NAME:-utils}" "$*"; }

# paths
command -v repo_root >/dev/null 2>&1 || repo_root(){
  git -C "${1:-$PWD}" rev-parse --show-toplevel 2>/dev/null || echo "${1:-$PWD}"
}

# env detection
command -v is_wsl  >/dev/null 2>&1 || is_wsl(){ grep -qi microsoft /proc/version 2>/dev/null; }
command -v os_id   >/dev/null 2>&1 || os_id(){ [ -r /etc/os-release ] && . /etc/os-release; echo "${ID:-linux}"; }
command -v arch_id >/dev/null 2>&1 || arch_id(){ uname -m; }

# PATH helper (idempotent)
command -v ensure_localbin_on_path >/dev/null 2>&1 || ensure_localbin_on_path(){
  mkdir -p "$HOME/.local/bin"
  case ":$PATH:" in *":$HOME/.local/bin:"*) :;; *) export PATH="$HOME/.local/bin:$PATH";; esac
  # persist for new shells (bash/zsh if present)
  for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    [[ -f "$rc" ]] || continue
    grep -qs 'HOME/.local/bin' "$rc" || printf '\nif [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then export PATH="$HOME/.local/bin:$PATH"; fi\n' >> "$rc"
  done
}

# symlink helper (idempotent)
command -v link_tool >/dev/null 2>&1 || link_tool(){
  # link_tool <src> <dst>
  local src="$1" dst="$2"
  [[ -e "$src" ]] || { info "missing $src"; return 1; }
  chmod +x "$src" 2>/dev/null || true
  ln -snf "$src" "$dst"
  info "linked $(basename "$src") -> $dst"
}



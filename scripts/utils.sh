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

goto(){
	local target_dir="$1"
	# Base directory containing user folders
	local users_base_dir="/mnt/c/Users"
	local ignore_file="$HOME/config/.bash_find_ignore"

	# Check if the target directory is a key in the associative array
	if [[ -n "${gotoPaths[$target_dir]}" ]]; then
		cd "${gotoPaths[$target_dir]}" || return
		return
	fi

	if ! command -v fd &> /dev/null; then
			echo "fd is not installed. Please install fd first."
			return 1
	fi


	# Initialize an array to store the paths of all 'Documents' directories
	local documents_dirs=()

	# Iterate over each directory in /mnt/c/Users to find 'Documents' folders
	for user_dir in "$users_base_dir"/*/; do
			if [ -d "${user_dir}Documents" ]; then
					documents_dirs+=("${user_dir}Documents")
			fi
	done

	# Check if no 'Documents' directories were found
	if [ ${#documents_dirs[@]} -eq 0 ]; then
			echo "No 'Documents' directories found under /mnt/c/Users."
			return 1
	fi

	# Initialize an array to hold the search results
	local search_results=()

	# Search for the target directory within each 'Documents' directory
	for doc_dir in "${documents_dirs[@]}"; do
			while IFS= read -r line; do
					search_results+=("$line")
			done < <(fd --type d --ignore-file "$ignore_file" --fixed-strings "$target_dir" "$doc_dir" 2>/dev/null)
	done

	# Use fzf to select from the search results
	local dir=$(printf "%s\n" "${search_results[@]}" | fzf --query="$target_dir" --select-1 --exit-0)

	if [ -z "$dir" ]; then
			echo "No directory found or selected."
			return 1
	fi

	# Change to the selected directory
	cd "$dir" || return
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



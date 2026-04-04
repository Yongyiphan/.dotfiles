#!/usr/bin/bash

echo "$DOTFILES_PROFILE" running custom
export EDITOR=/home/linuxbrew/.linuxbrew/bin/nvim
export VISUAL=/home/linuxbrew/.linuxbrew/bin/nvim

snvim() {
  sudo -E /home/linuxbrew/.linuxbrew/bin/nvim "$@"
}

alias svm=snvim

# List of virtual environment directory names to search for
venv_names=(
    ".venv"
    ".env" 
    "venv"
)

start() {
		echo "Starting application..."
    local search_dir=$(pwd)

    # Walk up directory tree until we hit root
    while [[ -n "$search_dir" ]]; do
        for venv_name in "${venv_names[@]}"; do
            local activate_path="${search_dir}/${venv_name}/bin/activate"
            
            # Check if activate script exists
            if [[ -f "$activate_path" ]]; then
                source "$activate_path"
                echo "✓ Activated: ${search_dir}/${venv_name}"
                return 0
            fi
        done

        # Move to parent directory (stop at root)
        local parent_dir=$(dirname "$search_dir")
        [[ "$parent_dir" == "$search_dir" ]] && break
        search_dir="$parent_dir"
    done

    echo "No virtual environment found in current or parent directories."
    return 1
}

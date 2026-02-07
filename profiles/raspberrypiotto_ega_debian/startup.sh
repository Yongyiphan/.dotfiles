#!/bin/bash
echo sourcing startup.sh
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

restart_ssh() {
    echo "Restarting SSH Agent..."

    # Detect if inside a tmux session
    if [ -n "$TMUX" ]; then
        echo "Detected inside a tmux session."
        eval $(tmux show-env -s SSH_AUTH_SOCK)
        echo "✓ SSH_AUTH_SOCK reassigned in tmux session: $SSH_AUTH_SOCK"
    fi
}

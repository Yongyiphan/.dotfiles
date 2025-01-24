#!/bin/bash

# Variables
DOTFILES_DIR=~/.dotfiles
BREWFILE="$DOTFILES_DIR/Brewfile"

# Save installed brew packages
save_brew_packages() {
    echo "Saving installed brew packages to $BREWFILE..."
    EDITOR=true brew bundle dump --file="$BREWFILE" --force
    echo "Brew packages saved."
}

# Restore brew packages
restore_brew_packages() {
    if [ -f "$BREWFILE" ]; then
        echo "Restoring brew packages from $BREWFILE..."
        brew bundle install --file="$BREWFILE"
        echo "Brew packages restored."
    else
        echo "No Brewfile found. Skipping brew package restoration."
    fi
}

# Call the appropriate function based on the argument
case "$1" in
    save)
        save_brew_packages
        ;;
    restore)
        restore_brew_packages
        ;;
    *)
        echo "Usage: $0 {save|restore}"
        exit 1
        ;;
esac


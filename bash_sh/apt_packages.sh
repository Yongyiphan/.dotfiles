#!/bin/bash

# Variables
DOTFILES_DIR=~/.dotfiles
APT_PACKAGE_LIST="$DOTFILES_DIR/apt-packages.txt"

# Save installed apt packages
save_apt_packages() {
    echo "Saving installed apt packages to $APT_PACKAGE_LIST..."
    dpkg --get-selections > "$APT_PACKAGE_LIST"
    echo "Apt package list saved."
}

# Restore apt packages
restore_apt_packages() {
    if [ -f "$APT_PACKAGE_LIST" ]; then
        echo "Restoring apt packages from $APT_PACKAGE_LIST..."
        sudo apt update
        xargs -a "$APT_PACKAGE_LIST" sudo apt install -y
        echo "Apt packages restored."
    else
        echo "No apt package list found. Skipping apt package restoration."
    fi
}

# Call the appropriate function based on the argument
case "$1" in
    save)
        save_apt_packages
        ;;
    restore)
        restore_apt_packages
        ;;
    *)
        echo "Usage: $0 {save|restore}"
        exit 1
        ;;
esac

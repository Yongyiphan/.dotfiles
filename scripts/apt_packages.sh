#!/bin/bash

# Variables
APT_PACKAGE_LIST="$DOTFILES/apt-packages.txt"

# Save installed apt packages with versions
save_apt_packages() {
    echo "Saving installed apt packages with specific versions to $APT_PACKAGE_LIST..."
    dpkg-query -W -f='${binary:Package}=${Version}\n' > "$APT_PACKAGE_LIST"
    echo "Apt package list with versions saved to $APT_PACKAGE_LIST."
}

# Restore apt packages with specific versions
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


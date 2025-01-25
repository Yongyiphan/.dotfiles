#!/bin/bash

# Variables
DOTFILES_DIR=~/.dotfiles
BACKUP_DIR=~/.dotfiles-backup

# Create a backup directory for existing dotfiles
mkdir -p $BACKUP_DIR

# Function to symlink files
link_file() {
    local src=$1
    local dest=$2

    # Backup existing file if it exists
    if [ -f "$dest" ] || [ -d "$dest" ]; then
        echo "Backing up $dest to $BACKUP_DIR"
        mv "$dest" "$BACKUP_DIR/"
    fi

    # Create symlink
    echo "Creating symlink: $dest -> $src"
    ln -sf "$src" "$dest"
}

# Symlink .config directory
link_file "$DOTFILES_DIR/.config" ~/.config

# Symlink other dotfiles
link_file "$DOTFILES_DIR/.profile" ~/.profile
link_file "$DOTFILES_DIR/.bashrc" ~/.bashrc
link_file "$DOTFILES_DIR/.zshrc" ~/.zshrc
link_file "$DOTFILES_DIR/.vimrc" ~/.vimrc
link_file "$DOTFILES_DIR/.gitconfig" ~/.gitconfig

echo "Symlinking complete!"

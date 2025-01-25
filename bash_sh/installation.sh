#!/bin/bash

# Function to install Homebrew
setup_brew() {
    if ! command -v brew &> /dev/null; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        echo "Homebrew installed."
    else
        echo "Homebrew is already installed."
    fi

    # Add Homebrew to PATH if not already present
    if ! grep -q "eval \"\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)\"" ~/.bashrc; then
        echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        echo "Homebrew added to PATH."
    fi
}

setup_brew

#!/usr/bin/env bash
# only for macOS/WSL if you want brew there
if [[ "$OS_TYPE" == "darwin" || "$OS_TYPE" == "linux" ]]; then
  if ! command -v brew &>/dev/null; then
    echo "🍺 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  # ensure brew env is loaded
  eval "$(brew shellenv)"

  if [ -f "$DOTFILES/Brewfile" ]; then
    echo "📦 Installing Homebrew packages from Brewfile..."
    brew bundle --file="$DOTFILES/Brewfile"
  fi
else
  echo "⏭  Skipping Homebrew on $OS_TYPE"
fi


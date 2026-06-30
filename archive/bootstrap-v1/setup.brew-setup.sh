#!/usr/bin/env bash
# only for macOS/WSL if you want brew there
if [[ "$OS_TYPE" == "darwin" || "$OS_TYPE" == "linux" ]]; then
  if ! command -v brew &>/dev/null; then
    echo "🍺 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  eval "$(brew shellenv)"

  if [ -f "$DOTFILES/Brewfile" ]; then
    echo "📦 Installing Homebrew packages from Brewfile..."
    brew bundle --file="$DOTFILES/Brewfile"
  fi
else
  echo "⏭  Skipping Homebrew on $OS_TYPE"
fi

save_brew_packages() {
    echo "Saving installed brew packages to $BREWFILE..."
		unset EDITOR VISUAL
    brew bundle dump --file="$BREWFILE" --force --describe
    echo "Brew packages saved."
}

restore_brew_packages() {
    if [ -f "$BREWFILE" ]; then
        echo "Restoring brew packages from $BREWFILE..."
        brew bundle install --file="$BREWFILE"
        echo "Brew packages restored."
    else
        echo "No Brewfile found. Skipping brew package restoration."
    fi
}

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

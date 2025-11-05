#!/usr/bin/env bash
# ~/.dotfiles/setup/install-core.sh
# Minimal Neovim setup (AppImage). No Python/Node providers.

set -euo pipefail

NVIM_VERSION="${NVIM_VERSION:-0.11.1}"
NVIM_APPIMAGE_URL="https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}/nvim.appimage"
BIN_DIR="$HOME/.local/bin"

# Optional toggles (0/1)
INSTALL_TOOLS="${INSTALL_TOOLS:-1}"      # ripgrep, fd  (handy, not required)
INSTALL_CLIPBOARD="${INSTALL_CLIPBOARD:-1}" # win32yank (WSL) or xclip/wl-clipboard (Linux)

log() { printf "\033[1;32m==>\033[0m %s\n" "$*"; }
warn(){ printf "\033[1;33mWARN:\033[0m %s\n" "$*"; }
err() { printf "\033[1;31mERROR:\033[0m %s\n" "$*" >&2; }

detect_pm() {
  command -v apt-get >/dev/null && { echo apt; return; }
  command -v dnf >/dev/null && { echo dnf; return; }
  command -v pacman >/dev/null && { echo pacman; return; }
  echo unknown
}

ensure_path_export() {
  local rc
  case "${SHELL##*/}" in
    bash) rc="$HOME/.bashrc" ;;
    zsh)  rc="$HOME/.zshrc" ;;
    *)    rc="$HOME/.profile" ;;
  esac
  if ! grep -qs 'export PATH="$HOME/.local/bin:$PATH"' "$rc"; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$rc"
    log "Added ~/.local/bin to PATH in $rc (restart shell to take effect)."
  fi
}

install_min_deps() {
  local pm; pm="$(detect_pm)"
  case "$pm" in
    apt)
      log "Installing minimal deps via apt…"
      sudo apt-get update -y
      # libfuse2 helps run the AppImage directly; if missing, we’ll auto-extract.
      sudo apt-get install -y curl ca-certificates git unzip xz-utils tar libfuse2 || true
      if [ "$INSTALL_TOOLS" = "1" ]; then
        sudo apt-get install -y ripgrep fd-find || true
      fi
      ;;
    dnf)
      log "Installing minimal deps via dnf…"
      sudo dnf install -y curl ca-certificates git unzip xz tar fuse || true
      [ "$INSTALL_TOOLS" = "1" ] && sudo dnf install -y ripgrep fd-find || true
      ;;
    pacman)
      log "Installing minimal deps via pacman…"
      sudo pacman -Sy --needed --noconfirm curl ca-certificates git unzip xz tar fuse2 || true
      [ "$INSTALL_TOOLS" = "1" ] && sudo pacman -Sy --needed --noconfirm ripgrep fd || true
      ;;
    *)
      warn "Unknown package manager. Ensure these exist: curl, git, unzip, xz, tar, (libfuse2)."
      ;;
  esac

  # Debian/Ubuntu call fd "fdfind"; create a friendly shim if tools enabled.
  if [ "$INSTALL_TOOLS" = "1" ] && command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
    mkdir -p "$BIN_DIR"
    ln -sf "$(command -v fdfind)" "$BIN_DIR/fd"
  fi
}

install_nvim_appimage() {
  mkdir -p "$BIN_DIR"
  ensure_path_export

  log "Downloading Neovim v${NVIM_VERSION} AppImage…"
  curl -fL "$NVIM_APPIMAGE_URL" -o "$BIN_DIR/nvim"
  chmod +x "$BIN_DIR/nvim"

  # If FUSE is missing, extract and use the real binary.
  if ! "$BIN_DIR/nvim" --version >/dev/null 2>&1; then
    log "AppImage failed (likely no FUSE). Extracting once…"
    ( cd "$BIN_DIR" && ./nvim --appimage-extract >/dev/null )
    ln -sf "$BIN_DIR/squashfs-root/usr/bin/nvim" "$BIN_DIR/nvim"
  fi

  "$BIN_DIR/nvim" --version | head -n1
  log "Neovim installed at $BIN_DIR/nvim"
}

install_clipboard_helper() {
  [ "$INSTALL_CLIPBOARD" = "1" ] || { log "Skipping clipboard helpers."; return; }

  # WSL detection
  if grep -qi microsoft /proc/version 2>/dev/null; then
    if ! command -v win32yank.exe >/dev/null 2>&1; then
      log "Installing win32yank.exe for WSL clipboard…"
      tmp="$(mktemp -d)"
      curl -fL -o "$tmp/win32yank.zip" https://github.com/equalsraf/win32yank/releases/download/v0.1.1/win32yank-x64.zip
      unzip -q "$tmp/win32yank.zip" -d "$tmp"
      install -m 0755 "$tmp/win32yank.exe" "$BIN_DIR/win32yank.exe"
      rm -rf "$tmp"
    fi
  else
    # X11/Wayland helpers (best-effort)
    local pm; pm="$(detect_pm)"
    case "$pm" in
      apt)    sudo apt-get install -y xclip wl-clipboard || true ;;
      dnf)    sudo dnf install -y xclip wl-clipboard || true ;;
      pacman) sudo pacman -Sy --needed --noconfirm xclip wl-clipboard || true ;;
    esac
  fi
}

main() {
  install_min_deps
  install_nvim_appimage
  install_clipboard_helper
  log "Done. Open a new shell (or 'exec \$SHELL -l') so PATH updates apply."
}

main "$@"


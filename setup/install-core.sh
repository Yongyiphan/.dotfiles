#!/usr/bin/env bash
# ~/.dotfiles/setup/install-core.sh
# Minimal Neovim install (AppImage-first with auto-fallback). No Python/Node providers.

set -euo pipefail

NVIM_VERSION="${NVIM_VERSION:-0.11.1}"   # keep pinned for consistency; override at runtime to upgrade
BIN_DIR="$HOME/.local/bin"
OPT_DIR="$HOME/.local/opt"

# Optional toggles (0/1)
INSTALL_TOOLS="${INSTALL_TOOLS:-1}"       # ripgrep, fd (handy but not required)
INSTALL_CLIPBOARD="${INSTALL_CLIPBOARD:-1}"

log()  { printf "\033[1;32m==>\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33mWARN:\033[0m %s\n" "$*"; }
err()  { printf "\033[1;31mERROR:\033[0m %s\n" "$*" >&2; }

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
    zsh)  rc="$HOME/.zshrc"  ;;
    *)    rc="$HOME/.profile";;
  esac
  if ! grep -qs 'export PATH="$HOME/.local/bin:$PATH"' "$rc"; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$rc"
    log "Added ~/.local/bin to PATH in $rc (restart shell to apply)."
  fi
}

install_min_deps() {
  local pm; pm="$(detect_pm)"
  case "$pm" in
    apt)
      log "Installing minimal deps (apt)…"
      sudo apt-get update -y
      sudo apt-get install -y curl ca-certificates git unzip xz-utils tar libfuse2 || true
      if [ "$INSTALL_TOOLS" = "1" ]; then
        sudo apt-get install -y ripgrep fd-find || true
        # Debian/Ubuntu name fd as fdfind → provide 'fd' shim
        if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
          mkdir -p "$BIN_DIR"; ln -sf "$(command -v fdfind)" "$BIN_DIR/fd"
        fi
      fi
      ;;
    dnf)
      log "Installing minimal deps (dnf)…"
      sudo dnf install -y curl ca-certificates git unzip xz tar fuse || true
      [ "$INSTALL_TOOLS" = "1" ] && sudo dnf install -y ripgrep fd-find || true
      ;;
    pacman)
      log "Installing minimal deps (pacman)…"
      sudo pacman -Sy --needed --noconfirm curl ca-certificates git unzip xz tar fuse2 || true
      [ "$INSTALL_TOOLS" = "1" ] && sudo pacman -Sy --needed --noconfirm ripgrep fd || true
      ;;
    *) warn "Unknown package manager. Ensure curl, git, unzip, xz, tar, (libfuse2) exist."; ;;
  esac
}

# Return 0 if URL exists (HTTP 200), else non-zero
url_ok() { curl -fsIL "$1" >/dev/null 2>&1; }

nvim_url_for_version() {
  local ver="v${NVIM_VERSION}"
  # 0.11.1 lives in neovim-releases with the long AppImage filename
  local app_urls=(
    "https://github.com/neovim/neovim-releases/releases/download/${ver}/nvim-linux-x86_64.appimage"
    "https://github.com/neovim/neovim/releases/download/${ver}/nvim.appimage"
  )
  local tar_urls=(
    "https://github.com/neovim/neovim-releases/releases/download/${ver}/nvim-linux64.tar.gz"
    "https://github.com/neovim/neovim/releases/download/${ver}/nvim-linux64.tar.gz"
  )

  for u in "${app_urls[@]}"; do
    if curl -fsIL "$u" >/dev/null; then echo "APPIMAGE::$u"; return; fi
  done
  for u in "${tar_urls[@]}"; do
    if curl -fsIL "$u" >/dev/null; then echo "TARBALL::$u"; return; fi
  done
  echo "NONE::" ; return 1
}

install_nvim() {
  mkdir -p "$BIN_DIR" "$OPT_DIR"
  ensure_path_export

  local kind_url
  kind_url="$(nvim_url_for_version)" || { err "Could not find Neovim $NVIM_VERSION assets."; exit 1; }
  local kind="${kind_url%%::*}"
  local url="${kind_url#*::}"

  if [ "$kind" = "APPIMAGE" ]; then
    log "Downloading Neovim $NVIM_VERSION (AppImage)…"
    curl -fL "$url" -o "$BIN_DIR/nvim"
    chmod +x "$BIN_DIR/nvim"
    # If FUSE missing, extract once
    if ! "$BIN_DIR/nvim" --version >/dev/null 2>&1; then
      log "AppImage failed to run (likely no FUSE). Extracting…"
      ( cd "$BIN_DIR" && ./nvim --appimage-extract >/dev/null )
      ln -sf "$BIN_DIR/squashfs-root/usr/bin/nvim" "$BIN_DIR/nvim"
    fi
  else
    log "Downloading Neovim $NVIM_VERSION (tarball)…"
    tmp="$(mktemp -d)"
    curl -fL "$url" -o "$tmp/nvim.tgz"
    tar -xzf "$tmp/nvim.tgz" -C "$tmp"
    rm -f "$tmp/nvim.tgz"
    rm -rf "$OPT_DIR/nvim-${NVIM_VERSION}" || true
    mv "$tmp"/nvim-linux64 "$OPT_DIR/nvim-${NVIM_VERSION}"
    ln -sf "$OPT_DIR/nvim-${NVIM_VERSION}/bin/nvim" "$BIN_DIR/nvim"
    rm -rf "$tmp"
  fi

  "$BIN_DIR/nvim" --version | head -n1
  log "Neovim installed at $BIN_DIR/nvim"
}

install_clipboard_helper() {
  [ "$INSTALL_CLIPBOARD" = "1" ] || { log "Skipping clipboard helpers."; return; }
  if grep -qi microsoft /proc/version 2>/dev/null; then
    if ! command -v win32yank.exe >/dev/null 2>&1; then
      log "Installing win32yank.exe (WSL clipboard)…"
      tmp="$(mktemp -d)"
      curl -fL -o "$tmp/win32yank.zip" https://github.com/equalsraf/win32yank/releases/download/v0.1.1/win32yank-x64.zip
      unzip -q "$tmp/win32yank.zip" -d "$tmp"
      install -m 0755 "$tmp/win32yank.exe" "$BIN_DIR/win32yank.exe"
      rm -rf "$tmp"
    fi
  else
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
  install_nvim
  install_clipboard_helper
  log "Done. Restart your shell (or run: exec \$SHELL -l)."
}

main "$@"


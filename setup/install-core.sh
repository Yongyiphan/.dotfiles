#!/usr/bin/env bash
# ~/.dotfiles/setup/install-core.sh
# Minimal Neovim install (AppImage-first with auto-fallback). No Python/Node providers.

set -euo pipefail

NVIM_VERSION="${NVIM_VERSION:-0.11.1}"   # keep pinned for consistency; override at runtime to upgrade
BIN_DIR="$HOME/.local/bin"
OPT_DIR="$HOME/.local/opt"

mkdir -p "$BIN_DIR" "$OPT_DIR"

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

has_fuse() {
  command -v fusermount >/dev/null 2>&1 || command -v fusermount3 >/dev/null 2>&1
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

# Return "APPIMAGE::<url>" or "TARBALL::<url>" for the current arch
nvim_url_for_version() {
  local ver="v${NVIM_VERSION}"
  local arch="$(uname -m)"
  local app_url=""
  local tar_url=""

  # AppImage (single binary)
  app_url="https://github.com/neovim/neovim-releases/releases/download/${ver}/nvim-linux-x86_64.appimage"
  if curl -fsIL "$app_url" >/dev/null 2>&1; then
    echo "APPIMAGE::$app_url"; return 0
  fi

  # Tarball variants by arch
  case "$arch" in
    x86_64|amd64)
      tar_url="https://github.com/neovim/neovim-releases/releases/download/${ver}/nvim-linux-x86_64.tar.gz"
      ;;
    aarch64|arm64)
      tar_url="https://github.com/neovim/neovim-releases/releases/download/${ver}/nvim-linux-arm64.tar.gz"
      ;;
    *)
      # Fallback to upstream name if unknown arch
      tar_url="https://github.com/neovim/neovim/releases/download/${ver}/nvim-linux64.tar.gz"
      ;;
  esac

  if curl -fsIL "$tar_url" >/dev/null 2>&1; then
    echo "TARBALL::$tar_url"; return 0
  fi

  echo "NONE::"; return 1
}

install_nvim() {
  mkdir -p "$BIN_DIR" "$OPT_DIR"
  ensure_path_export

  local kind_url kind url tmp
  kind_url="$(nvim_url_for_version)" || { err "Could not find Neovim $NVIM_VERSION assets for your arch."; exit 1; }
  kind="${kind_url%%::*}"
  url="${kind_url#*::}"

  if [ "${NVIM_FORCE_TARBALL:-0}" = "1" ]; then
    kind="TARBALL"
  fi

  if [ "$kind" = "APPIMAGE" ]; then
    log "Downloading Neovim $NVIM_VERSION (AppImage)…"
    tmp="$(mktemp --tmpdir nvim.app.XXXXXX || mktemp -t nvim.app)"
    if ! curl -fL "$url" -o "$tmp"; then
      warn "AppImage download failed, falling back to tarball"
      NVIM_FORCE_TARBALL=1 install_nvim; return
    fi
    install -m 0755 "$tmp" "$BIN_DIR/nvim"
    rm -f "$tmp"

    if has_fuse && "$BIN_DIR/nvim" --version >/dev/null 2>&1; then
      :
    else
      log "FUSE not available or AppImage failed; extracting once…"
      local exdir="$OPT_DIR/nvim-appimage-${NVIM_VERSION}"
      rm -rf "$exdir"
      mkdir -p "$exdir"
      ( cd "$exdir" && "$BIN_DIR/nvim" --appimage-extract >/dev/null )
      ln -sf "$exdir/squashfs-root/usr/bin/nvim" "$BIN_DIR/nvim"
    fi
  else
    log "Downloading Neovim $NVIM_VERSION (tarball)…"
    tmp="$(mktemp --tmpdir nvim.tgz.XXXXXX || mktemp -t nvim.tgz)"
    if ! curl -fL "$url" -o "$tmp"; then
      err "Tarball download failed from $url"; exit 1
    fi
    local dest="$OPT_DIR/nvim-${NVIM_VERSION}"
    rm -rf "$dest"
    mkdir -p "$OPT_DIR"
    # Extract to a temp dir then move atomically
    local tdir; tdir="$(mktemp -d "${OPT_DIR}/nvim.extract.XXXXXX" 2>/dev/null || mktemp -d)"
    tar -xzf "$tmp" -C "$tdir"
    rm -f "$tmp"
    # The tarball unpacks to nvim-linux-<arch>
    local unpack_dir
    unpack_dir="$(find "$tdir" -maxdepth 1 -type d -name 'nvim-*' -print -quit)"
    if [ -z "$unpack_dir" ]; then
      err "Unexpected tarball layout; could not find nvim-* directory"; rm -rf "$tdir"; exit 1
    fi
    mv "$unpack_dir" "$dest"
    rm -rf "$tdir"
    ln -sf "$dest/bin/nvim" "$BIN_DIR/nvim"
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


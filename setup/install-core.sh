#!/usr/bin/env bash
# ~/.dotfiles/setup/install-core.sh
# Minimal Neovim install (AppImage-first with auto-fallback). No Python/Node providers.

set -euo pipefail

NVIM_VERSION="${NVIM_VERSION:-0.11.1}"   # keep pinned for consistency; override at runtime to upgrade
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
OPT_DIR="${OPT_DIR:-$HOME/.local/opt}"

# Optional toggles (0/1)
INSTALL_TOOLS="${INSTALL_TOOLS:-1}"      # ripgrep, fd (handy but not required)
INSTALL_CLIPBOARD="${INSTALL_CLIPBOARD:-1}"

log()  { printf "\033[1;32m==>\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33mWARN:\033[0m %s\n" "$*"; }
err()  { printf "\033[1;31mERROR:\033[0m %s\n" "$*" >&2; }

ensure_dirs() {
  mkdir -p "$BIN_DIR" "$OPT_DIR"
}

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
  if ! grep -qs 'export PATH="$HOME/.local/bin:$PATH"' "$rc" 2>/dev/null; then
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
    *)
      warn "Unknown package manager. Ensure curl, git, unzip, xz, tar, (libfuse2) exist."
      ;;
  esac
}

# Basic HEAD check for availability
url_ok() { curl -fsIL "$1" >/dev/null 2>&1; }

detect_arch() {
  case "$(uname -m)" in
    x86_64|amd64) echo "x86_64" ;;
    aarch64|arm64) echo "arm64" ;;
    *) echo "x86_64" ;; # default to x86_64
  esac
}

nvim_appimage_url() {
  local ver="v${NVIM_VERSION}"
  local arch; arch="$(detect_arch)"
  # Primary location for 0.11.x+
  echo "https://github.com/neovim/neovim-releases/releases/download/${ver}/nvim-linux-${arch}.appimage"
}

nvim_tarball_url() {
  local ver="v${NVIM_VERSION}"
  local arch; arch="$(detect_arch)"
  # Primary tarballs per arch
  case "$arch" in
    x86_64) echo "https://github.com/neovim/neovim-releases/releases/download/${ver}/nvim-linux-x86_64.tar.gz" ;;
    arm64)  echo "https://github.com/neovim/neovim-releases/releases/download/${ver}/nvim-linux-arm64.tar.gz" ;;
  esac
}

install_from_appimage() {
  ensure_dirs
  ensure_path_export

  local url tmp
  url="$(nvim_appimage_url)"
  log "Downloading Neovim ${NVIM_VERSION} (AppImage)…"
  tmp="$(mktemp --tmpdir nvim.app.XXXXXX 2>/dev/null || mktemp -t nvim.app)"

  if ! curl -fL "$url" -o "$tmp"; then
    err "AppImage download failed from $url"
    return 1
  fi

  chmod +x "$tmp"
  install -m 0755 "$tmp" "$BIN_DIR/nvim"
  rm -f "$tmp"

  # Try running; if FUSE not available, extract-once path
  if "$BIN_DIR/nvim" --version >/dev/null 2>&1; then
    "$BIN_DIR/nvim" --version | head -n 1
    log "Neovim installed at $BIN_DIR/nvim (AppImage)."
    return 0
  fi

  if ! has_fuse; then
    log "FUSE not available; extracting AppImage once…"
    local exdir="$OPT_DIR/nvim-appimage-${NVIM_VERSION}"
    rm -rf "$exdir"
    mkdir -p "$exdir"
    if ( cd "$exdir" && "$BIN_DIR/nvim" --appimage-extract >/dev/null ); then
      ln -sfn "$exdir/squashfs-root/usr/bin/nvim" "$BIN_DIR/nvim"
      "$BIN_DIR/nvim" --version | head -n 1
      log "Neovim installed at $BIN_DIR/nvim (extracted AppImage)."
      return 0
    else
      err "AppImage extraction failed."
      return 1
    fi
  else
    err "AppImage failed to run even though FUSE seems present."
    return 1
  fi
}

install_from_tarball() {
  ensure_dirs
  ensure_path_export

  local url tmp tdir dest unpack_dir
  url="$(nvim_tarball_url)"
  log "Downloading Neovim ${NVIM_VERSION} (tarball)…"
  tmp="$(mktemp --tmpdir nvim.tgz.XXXXXX 2>/dev/null || mktemp -t nvim.tgz)"
  if ! curl -fL "$url" -o "$tmp"; then
    err "Tarball download failed from $url"
    return 1
  fi

  dest="$OPT_DIR/nvim-${NVIM_VERSION}"
  rm -rf "$dest"
  mkdir -p "$OPT_DIR"

  tdir="$(mktemp -d "${OPT_DIR}/nvim.extract.XXXXXX" 2>/dev/null || mktemp -d)"
  if ! tar -xzf "$tmp" -C "$tdir"; then
    err "Tar extraction failed (file may not be a valid gzip)."
    rm -f "$tmp"; rm -rf "$tdir"
    return 1
  fi
  rm -f "$tmp"

  # Neovim tarballs unpack to nvim-linux-<arch>
  unpack_dir="$(find "$tdir" -maxdepth 1 -type d -name 'nvim-*' -print -quit)"
  if [ -z "$unpack_dir" ]; then
    err "Unexpected tarball layout; nvim-* dir not found."
    rm -rf "$tdir"
    return 1
  fi

  mv "$unpack_dir" "$dest"
  rm -rf "$tdir"
  ln -sfn "$dest/bin/nvim" "$BIN_DIR/nvim"

  "$BIN_DIR/nvim" --version | head -n 1
  log "Neovim installed at $BIN_DIR/nvim (tarball)."
  return 0
}

install_clipboard_helper() {
  [ "$INSTALL_CLIPBOARD" = "1" ] || { log "Skipping clipboard helpers."; return; }
  if grep -qi microsoft /proc/version 2>/dev/null; then
    if ! command -v win32yank.exe >/dev/null 2>&1; then
      log "Installing win32yank.exe (WSL clipboard)…"
      local tmp; tmp="$(mktemp -d)"
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
  ensure_dirs
  ensure_path_export

  install_min_deps

  # If user forces tarball, try that first.
  if [ "${NVIM_FORCE_TARBALL:-0}" = "1" ]; then
    if install_from_tarball; then
      install_clipboard_helper
      log "Done. Restart your shell (or run: exec \$SHELL -l)."
      exit 0
    else
      err "Tarball path failed; aborting."
      exit 1
    fi
  fi

  # Try AppImage first; on failure, fall back to tarball.
  if install_from_appimage; then
    install_clipboard_helper
    log "Done. Restart your shell (or run: exec \$SHELL -l)."
    exit 0
  else
    warn "AppImage path failed; falling back to tarball…"
    if install_from_tarball; then
      install_clipboard_helper
      log "Done. Restart your shell (or run: exec \$SHELL -l)."
      exit 0
    else
      err "Both AppImage and tarball installs failed."
      exit 1
    fi
  fi
}

main "$@"

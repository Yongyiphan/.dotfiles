#!/usr/bin/env bash
# dotfiles/scripts/detect-os.sh
# Source this file (don't execute) to populate OS/PM facts for your other scripts.

# No `set -e` here; this file is meant to be sourced safely.

# ---------- helpers ----------
_has() { command -v "$1" >/dev/null 2>&1; }

# ---------- kernel / arch ----------
OS_KERNEL="$(uname -s 2>/dev/null || echo unknown)"
OS_ARCH="$(uname -m 2>/dev/null || echo unknown)"
IS_WSL=0
if [[ -f /proc/sys/kernel/osrelease ]] && grep -qiE 'microsoft|wsl' /proc/sys/kernel/osrelease 2>/dev/null; then
  IS_WSL=1
fi

# ---------- type / distro ----------
OS_TYPE=linux
DISTRO_ID=unknown
DISTRO_FAMILY=unknown
PM=unknown

if [[ "$OS_KERNEL" == "Darwin" ]]; then
  OS_TYPE=darwin
  DISTRO_ID=macos
  DISTRO_FAMILY=darwin
  PM=brew
else
  # Linux (or unknown treated as Linux-like)
  if [[ -f /etc/NIXOS || -d /nix || -d /nix/store ]]; then
    OS_TYPE=nixos
    DISTRO_ID=nixos
    DISTRO_FAMILY=nixos
    PM=nix
  elif [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    DISTRO_ID="${ID:-linux}"
    DISTRO_FAMILY="${ID_LIKE:-$ID}"
  fi

  # choose package manager by availability
  if   _has apt-get; then PM=apt
  elif _has dnf;     then PM=dnf
  elif _has yum;     then PM=yum
  elif _has pacman;  then PM=pacman
  elif _has apk;     then PM=apk
  elif _has zypper;  then PM=zypper
  elif _has brew;    then PM=brew
  fi
fi

# ---------- sudo helper ----------
if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then SUDO=""; else SUDO="sudo"; fi

# ---------- default install priority for your install.sh ----------
# You currently support apt/tar/brew. Pick good defaults per host.
case "$OS_TYPE:$PM" in
  darwin:brew)     INSTALL_PRIORITY="brew,tar" ;;
  linux:apt)       INSTALL_PRIORITY="apt,tar,brew" ;;
  linux:brew)      INSTALL_PRIORITY="brew,tar,apt" ;;
  nixos:*)         INSTALL_PRIORITY="tar,brew" ;;   # apt not present; tar/brew as fallbacks
  *)               INSTALL_PRIORITY="apt,tar,brew" ;; # safe generic
esac

# ---------- convenience predicates ----------
is_linux()   { [[ "$OS_TYPE" == "linux" ]]; }
is_darwin()  { [[ "$OS_TYPE" == "darwin" ]]; }
is_nixos()   { [[ "$OS_TYPE" == "nixos" ]]; }
is_debian_like() { [[ "$DISTRO_FAMILY" =~ (debian|ubuntu|raspbian) ]]; }

# ---------- exports ----------
export OS_TYPE OS_KERNEL OS_ARCH IS_WSL DISTRO_ID DISTRO_FAMILY PM SUDO INSTALL_PRIORITY

# Optional: echo a one-liner when invoked directly
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  printf "OS_TYPE=%s PM=%s DISTRO_ID=%s IS_WSL=%s PRIORITY=%s\n" \
    "$OS_TYPE" "$PM" "$DISTRO_ID" "$IS_WSL" "$INSTALL_PRIORITY"
fi

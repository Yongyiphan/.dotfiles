#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -eq 0 ]; then
  echo "No system packages requested."
  exit 0
fi

detect_pm() {
  if command -v apt-get >/dev/null 2>&1; then
    echo apt
    return
  fi
  if command -v dnf >/dev/null 2>&1; then
    echo dnf
    return
  fi
  if command -v pacman >/dev/null 2>&1; then
    echo pacman
    return
  fi
  if command -v brew >/dev/null 2>&1; then
    echo brew
    return
  fi
  echo unknown
}

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  SUDO="sudo"
fi

PM="$(detect_pm)"
echo "Installing system packages with ${PM}: $*"

case "$PM" in
  apt)
    $SUDO apt-get update -y
    $SUDO apt-get install -y "$@"
    ;;
  dnf)
    $SUDO dnf install -y "$@"
    ;;
  pacman)
    $SUDO pacman -Sy --needed --noconfirm "$@"
    ;;
  brew)
    brew install "$@"
    ;;
  *)
    echo "Unsupported package manager. Install these packages manually: $*" >&2
    exit 1
    ;;
esac

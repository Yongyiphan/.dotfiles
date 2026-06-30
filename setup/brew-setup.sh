#!/usr/bin/env bash
set -euo pipefail

DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

case "${1:-restore}" in
  save)
    exec "$DOTFILES_ROOT/setup/freeze_catalog.sh" "${@:2}"
    ;;
  restore)
    exec "$DOTFILES_ROOT/setup/bootstrap.sh" "${@:2}"
    ;;
  *)
    echo "setup/brew-setup.sh is deprecated. Use setup/bootstrap.sh or setup/freeze_catalog.sh." >&2
    exit 1
    ;;
esac

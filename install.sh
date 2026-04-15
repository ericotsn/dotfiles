#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTFILES_DIR

print_error() {
  printf '\033[31m%-10s\033[0m%s\n' '[ERROR]' "$1"
}

print_success() {
  printf '\033[32m%-10s\033[0m%s\n' '[OK]' "$1"
}

print_warning() {
  printf '\033[33m%-10s\033[0m%s\n' '[WARN]' "$1"
}

print_info() {
  printf '\033[36m%-10s\033[0m%s\n' '[INFO]' "$1"
}

install_linux() {
  source "${DOTFILES_DIR}/install/packages.sh" || true
  source "${DOTFILES_DIR}/install/setup-fish.sh" || true
  source "${DOTFILES_DIR}/install/1password-linux.sh" || true

  if ! command -v wezterm >/dev/null 2>&1; then
    sudo dnf copr enable wezfurlong/wezterm-nightly
    sudo dnf install wezterm
  fi

  if ! command -v lazygit >/dev/null 2>&1; then
    sudo dnf copr enable dejan/lazygit
    sudo dnf install lazygit
  fi

  source "${DOTFILES_DIR}/install/pragmatapro.sh" || true
}

install_macos() {
  source "${DOTFILES_DIR}/install/homebrew.sh" || true
  source "${DOTFILES_DIR}/install/packages.sh" || true
  source "${DOTFILES_DIR}/install/setup-fish.sh" || true
  source "${DOTFILES_DIR}/install/pragmatapro.sh" || true
}

main() {
  OS_TYPE="${1:-}"

  case "${OS_TYPE}" in
  linux)
    install_linux
    ;;
  macos)
    install_macos
    ;;
  *)
    print_error 'Unsupported operating system'
    exit 1
    ;;
  esac

  print_success 'Installation completed! 🎉'
}

main "$@"

#!/usr/bin/env bash

bundle="${DOTFILES_DIR}/packages/${OS_TYPE}_bundle"

if [[ ! -f "${bundle}" ]]; then
  print_error "No such file or directory: '${bundle}'"
  return 1
fi

case "${OS_TYPE}" in
linux)
  cmd=(xargs -a "${bundle}" sudo dnf install -y)
  ;;
macos)
  cmd=(brew bundle --file="${bundle}")
  ;;
*)
  print_error 'Unsupported operating system'
  return 1
  ;;
esac

if "${cmd[@]}"; then
  print_success 'All packages installed successfully'
else
  print_warning 'Some packages failed to install'
fi

if ! command -v fnm >/dev/null 2>&1; then
  curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
fi

if ! command -v rustup >/dev/null 2>&1; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
fi

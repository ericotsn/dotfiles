#!/usr/bin/env bash

bundle="${DOTFILES_DIR}/packages/bundle"

if [[ ! -f "${bundle}" ]]; then
  print_error "No such file or directory: '${bundle}'"
  return 1
fi

if brew bundle --file="${bundle}"; then
  print_success 'All packages installed successfully'
else
  print_warning 'Some packages failed to install'
fi

#!/usr/bin/env bash

if command -v nvim >/dev/null 2>&1; then
  print_success 'Neovim is already installed'
  return 0
fi

local tmp_file
tmp_file="$(mktemp)"

print_info 'Downloading latest Neovim release from GitHub...'
curl -fsSL https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage -o "${tmp_file}"
chmod u+x "${tmp_file}"
mkdir -p "${HOME}/.local/bin"
mv "${tmp_file}" "${HOME}/.local/bin/nvim"

print_success 'Neovim installed successfully'
